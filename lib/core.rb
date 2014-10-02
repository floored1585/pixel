#!/usr/bin/env ruby

module Core

  def list_devices(settings, db)
    devices = []
    db[:device].select(:device).each { |row| devices.push(row[:device]) }
    return devices
  end

  def get_ints_down(settings, db)
    interfaces = db[:interface].filter(Sequel.like(:if_alias, 'sub%') | Sequel.like(:if_alias, 'bb%'))
    interfaces = interfaces.exclude(:if_oper_status => 1).exclude(:if_type => 'acc')

    (devices, name_to_index) = _device_map(interfaces, {}, {})
    _fill_metadata!(devices, settings, name_to_index)

    # Delete the interface from the hash if its parent is present, to reduce clutter
    devices.each do |device,int|
      int.delete_if { |index,oids| oids[:my_parent] && int[oids[:my_parent]] }
    end
    return devices
  end

  def get_ints_saturated(settings, db)
    interfaces = db[:interface].filter{ (bps_in_util > 90) | (bps_out_util > 90) }

    (devices, name_to_index) = _device_map(interfaces, {}, {})
    _fill_metadata!(devices, settings, name_to_index)
    return devices
  end

  def get_ints_discarding(settings, db)
    interfaces = db[:interface].filter{Sequel.|(
      Sequel.&(
        pps_out > 0, # Prevent div by zero
        discards_out > 20,
        ~Sequel.like(:if_alias, 'sub%'), # Don't look at sub-interfaces
        discards_out / pps_out.cast(:float) >= 0.01 # Filter out anything discarding <= 1%
      ),
      discards_out > 500 # Also include anything discarding over 500pps
    )}
    interfaces = interfaces.order(:discards_out).reverse

    (devices, name_to_index) = _device_map(interfaces, {}, {})
    _fill_metadata!(devices, settings, name_to_index)
    return devices
  end

  def get_device(settings, db, device, component=nil)
    interfaces = db[:interface]
    memory = db[:memory]
    cpus = db[:cpu]
    # Filter if a device was specified, otherwise return all
    if device
      # Return an empty hash if the device doesn't exist
      return {} if db[:device].filter(:device => device).empty?
      interfaces = interfaces.filter(:device => device)
      memory = memory.filter(:device => device)
      cpus = cpus.filter(:device => device)
    end

    # Return just an empty device if there are no CPUs or interfaces for the device
    return { device => {} } if cpus.empty? && interfaces.empty? && device

    (devices, name_to_index) = _device_map(interfaces, cpus, memory)
    _fill_metadata!(devices, settings, name_to_index)

    # If we only want certain components, delete the others
    if component
      devices.each do |dev,data|
        data.delete_if { |k,v| k.to_s != component }
      end
    end

    return devices
  end

  def get_cpus_high(settings, db)
    cpus = db[:cpu].filter{ util > 85 }

    (devices, name_to_index) = _device_map({}, cpus, {})
    return devices
  end

  def get_memory_high(settings, db)
    memory = db[:memory].filter{ util > 90 }

    (devices, name_to_index) = _device_map({}, {}, memory)
    return devices
  end

  def get_devices_poller(settings, db, count, poller_name)
    db.disconnect
    currently_polling = db[:device].filter{Sequel.&(
      {:currently_polling => 1, :worker => poller_name}, 
      last_poll > Time.now.to_i - 1000,
    )}.count
    count = count - currently_polling

    # Don't return more work if this poller is maxed out
    return {} if count < 1

    devices = {}
    # Fetch some devices and mark them as polling
    db.transaction do
      rows = db[:device].filter{ next_poll < Time.now.to_i }
      rows = rows.filter{Sequel.|({:currently_polling => 0}, (last_poll < Time.now.to_i - 1000))}
      rows = rows.limit(count).for_update

      rows.each do |row|
        devices[row[:device]] = row
        $LOG.warn("CORE: Overriding currently_polling for #{row[:device]} (#{poller_name})") if row[:currently_polling] == 1
        device_row = db[:device].where(:device => row[:device])
        device_row.update(
          :currently_polling => 1,
          :worker => poller_name,
          :last_poll => Time.now.to_i,
        )
      end
    end
    return devices
  end

  def post_devices(settings, db, devices)
    _validate_devices_post!(devices)

    devices.each do |device, data|

      metadata = data[:metadata]
      interfaces = data[:interfaces]

      $LOG.info("CORE: Received data for #{device} from #{data[:metadata][:worker]}")

      data[:interfaces].each do |index, data|
        #$LOG.warn("Device: #{device}  Interface: #{index}\n  OIDs: #{oids}")
        # Try updating, and if we don't affect a row, insert instead
        existing = db[:interface].where(:device => data[:device], :index => index)
        if existing.update(data) != 1
          db[:interface].insert(data)
        end
      end
      data[:cpus].each do |index, data|
        #$LOG.warn("Device: #{device}  CPU: #{index}\n  Data: #{data}")
        # Try updating, and if we don't affect a row, insert instead
        existing = db[:cpu].where(:device => data[:device], :index => index)
        if existing.update(data) != 1
          db[:cpu].insert(data)
        end
      end
      data[:memory].each do |index, data|
        #$LOG.warn("Device: #{device} Memory: #{index}\n  Data: #{data}")
        # Try updating, and if we don't affect a row, insert instead
        existing = db[:memory].where(:device => data[:device], :index => index)
        if existing.update(data) != 1
          db[:memory].insert(data)
        end
      end
      existing = db[:device].where(:device => device)
      if existing.update(metadata) != 1
        $LOG.error("Problem updating metadata for #{device}")
      end

      # Update the rest of the device attributes
      db[:device].where(:device => device).update(
        :currently_polling => 0,
        :worker => nil,
        :next_poll => Time.now.to_i + 100,
      )
    end
    return true
  end

  def populate_device_table(settings, db)
    db.disconnect
    devices = {}

    # Load from file
    if settings['device_source']['type'] = 'file'
      device_file = settings['device_source']['file_path']
      if File.exists?(device_file)
        devices = YAML.load_file(File.join(APP_ROOT, device_file))
      else
        $LOG.error("CORE: Error populating devices from file: File not found: #{device_file}")
      end
      $LOG.info("CORE: Importing #{devices.size} devices from file: #{device_file}")
    end

    API.post('core', '/v1/devices/replace', devices, 'CORE', 'new devices')
  end

  def add_devices(settings, db, devices, replace)
    db.disconnect
    devices.each do |device, ip|
      existing = db[:device].where(:device => device)
      if existing.update(:ip => ip) != 1
        $LOG.info("CORE: Adding new device: #{device}")
        db[:device].insert(:device => device, :ip => ip)
      end
    end
    if replace
      # Delete any devices that weren't provided
      existing = db[:device].select(:device, :ip).to_hash(:device).keys
      to_delete = existing - devices.keys
      to_delete.each do |device|
        $LOG.warn("CORE: Deleting device #{device}; not in new device set")
        db[:device].filter(:device => device).delete
      end
    end
    # need error detection
    return true
  end

  def delete_devices(settings, db, devices, partial)
    db.disconnect
    # If partial is true, we're going to delete individual things
    # Otherwise, delete the whole device
    if partial
      devices.each do |device, components|
        components.each do |component, indexes|
          indexes.each do |index|
            $LOG.warn("CORE: Removing interface ID #{index} on #{device} from database")
            db[component.to_sym].filter(:index => index).delete
          end
        end
      end
    else
      devices.keys.each do |device|
        $LOG.warn("CORE: Removing device #{device} from database")
        db[:device].filter(:device => device).delete
      end
    end
    return true
  end

  def _device_map(interfaces, cpus, memory)
    devices = {}
    name_to_index = {}

    interfaces.each do |row|
      index = row[:index]
      device = row[:device]

      devices[device] ||= { :interfaces => {} }
      name_to_index[device] ||= {}

      devices[device][:interfaces][index] = row
      name_to_index[device][row[:if_name].downcase] = index
    end
    cpus.each do |row|
      index = row[:index]
      device = row[:device]

      devices[device] ||= {}
      devices[device][:cpus] ||= {}
      devices[device][:cpus][index] = row
    end
    memory.each do |row|
      index = row[:index]
      device = row[:device]

      devices[device] ||= {}
      devices[device][:memory] ||= {}
      devices[device][:memory][index] = row
    end

    return devices, name_to_index
  end

  def _fill_metadata!(devices, settings, name_to_index)
    devices.each do |device,data|
      interfaces = data[:interfaces] || {}
      interfaces.each do |index,oids|
        # Populate 'neighbor' value
        oids[:if_alias].to_s.match(/__[a-zA-Z0-9\-_]+__/) do |neighbor|
          interfaces[index][:neighbor] = neighbor.to_s.gsub('__','')
        end

        time_since_poll = Time.now.to_i - oids[:last_updated]
        oids[:stale] = time_since_poll if time_since_poll > settings['stale_timeout']

        if oids[:pps_out] && oids[:pps_out] != 0
          oids[:discards_out_pct] = '%.2f' % (oids[:discards_out].to_f / oids[:pps_out] * 100)
        end

        # Populate 'link_type' value (Backbone, Access, etc...)
        oids[:if_alias].match(/^[a-z]+(__|\[)/) do |type|
          type = type.to_s.gsub(/(_|\[)/,'')
          oids[:link_type] = settings['link_types'][type]
          if type == 'sub'
            oids[:is_child] = true
            # This will return po1 from sub[po1]__gar-k11u1-dist__g1/47
            parent = oids[:if_alias][/\[[a-zA-Z0-9\/-]+\]/].gsub(/(\[|\])/, '')
            if parent && parent_index = name_to_index[device][parent.downcase]
              interfaces[parent_index][:is_parent] = true
              interfaces[parent_index][:children] ||= []
              interfaces[parent_index][:children] << index
              oids[:my_parent] = parent_index
            end
            oids[:my_parent_name] = parent.gsub('po','Po')
          end
        end

        oids[:if_oper_status] == 1 ? oids[:link_up] = true : oids[:link_up] = false
      end
    end
  end

  def _validate_devices_post!(devices)
    if devices.class == Hash
      devices.each do |device, data|
        if data.class == Hash
          data.symbolize!
          # Validata metadata
          if data[:metadata].class == Hash
            data[:metadata].symbolize!
          else
            $LOG.warn("Invalid or missing metadata received for #{device}")
            data[:metadata] = {}
          end
          # Validate interfaces
          if data[:interfaces].class == Hash
            # Validate OIDs
            data[:interfaces].each do |index, oids|
              if oids.class == Hash
                oids.symbolize!
              else
                $LOG.warn("Invalid or missing interface data for #{device}: index #{index}")
                data[:interfaces].delete(index)
              end
              required_data = [:device, :index, :last_updated, :if_alias, :if_name, :if_mtu,
                               :if_hc_in_octets, :if_hc_out_octets, :if_hc_in_ucast_pkts,
                               :if_hc_out_ucast_pkts, :if_high_speed, :if_admin_status, 
                               :if_admin_status_time, :if_oper_status, :if_oper_status_time,
                               :if_in_discards, :if_in_errors, :if_out_discards, :if_out_errors]
              unless (required_data - oids.keys).empty?
                $LOG.warn("Incomplete OIDs for #{device}: index #{index}. Missing: #{required_data - oids.keys}")
                data[:interfaces].delete(index)
              end
            end
          else
            $LOG.warn("Invalid or missing interfaces received for #{device}")
            data[:interfaces] = {}
          end
          # Validate CPUs
          if data[:cpus].class == Hash
            # Validate CPU data
            data[:cpus].each do |index, cpu_data|
              if cpu_data.class == Hash
                cpu_data.symbolize!
              else
                $LOG.warn("Invalid CPU data for #{device}: index #{index}")
                data[:cpus].delete(index)
              end
              # Convert utilization to numeric
              cpu_data[:util] = cpu_data[:util].to_i_if_numeric if cpu_data[:util]
              required_data = [:device, :index, :util, :description, :last_updated]
              unless (required_data - cpu_data.keys).empty?
                $LOG.warn("Invalid CPU for #{device}: index #{index}. Missing: #{required_data - cpu_data.keys}")
                data[:cpus].delete(index)
              end
              unless cpu_data[:util] && cpu_data[:util].is_a?(Numeric)
                $LOG.warn("Invalid or missing CPU utilization for #{device}: index #{index}")
                data[:cpus].delete(index)
              end
            end
          else
            $LOG.warn("Invalid or missing CPU received for #{device}")
            data[:cpus] = {}
          end
          # Validate Memory
          if data[:memory].class == Hash
            # Validate Memory data
            data[:memory].each do |index, mem_data|
              if mem_data.class == Hash
                mem_data.symbolize!
              else
                $LOG.warn("Invalid Memory data for #{device}: index #{index}")
                data[:memory].delete(index)
              end
              # Convert utilization to numeric
              mem_data[:util] = mem_data[:util].to_i_if_numeric if mem_data[:util]
              required_data = [:device, :index, :util, :description, :last_updated]
              unless (required_data - mem_data.keys).empty?
                $LOG.warn("Invalid Memory data for #{device}: index #{index}. Missing: #{required_data - mem_data.keys}")
                data[:memory].delete(index)
              end
              unless mem_data[:util] && mem_data[:util].is_a?(Numeric)
                $LOG.warn("Invalid or missing Memory utilization for #{device}: index #{index}")
                data[:memory].delete(index)
              end
            end
          else
            $LOG.warn("Invalid or missing Memory data received for #{device}")
            data[:memory] = {}
          end
        else
          $LOG.error("Invalid or missing data received for #{device}")
          devices[device] = {}
        end
      end
    else
      $LOG.error("Invalid devices received")
      devices = {}
    end
    return devices
  end

end
