#!/usr/bin/env ruby

module Core

  def get_ints_down(settings, db)
    rows = db[:interface].filter(Sequel.like(:if_alias, 'sub%') | Sequel.like(:if_alias, 'bb%'))
    rows = rows.exclude(:if_oper_status => 1)

    (devices, name_to_index) = _interface_map(rows)
    _fill_metadata!(devices, settings, name_to_index)

    # Delete the interface from the hash if its parent is present, to reduce clutter
    devices.each do |device,int|
      int.delete_if { |index,oids| oids[:my_parent] && int[oids[:my_parent]] }
    end
    return devices
  end

  def get_ints_saturated(settings, db)
    rows = db[:interface].filter{ (bps_in_util > 90) | (bps_out_util > 90) }

    (devices, name_to_index) = _interface_map(rows)
    _fill_metadata!(devices, settings, name_to_index)
    return devices
  end

  def get_ints_discarding(settings, db)
    rows = db[:interface].filter{Sequel.&(discards_out > 9, ~Sequel.like(:if_alias, 'sub%'))}
    rows = rows.order(:discards_out).reverse.limit(10)

    (devices, name_to_index) = _interface_map(rows)
    _fill_metadata!(devices, settings, name_to_index)
    return devices
  end

  def get_ints_device(settings, db, device)
    rows = db[:interface]
    # Filter If a device was specified, otherwise return all
    rows = rows.filter(:device => device) if device

    # If the device has no interfaces but does exist, just return the device name
    return { device => {} } if rows.empty? && !db[:device].filter(:device => device).empty?

    (devices, name_to_index) = _interface_map(rows)
    _fill_metadata!(devices, settings, name_to_index)
    return devices
  end

  def get_devices_poller(settings, db, count, poller_name)
    db.disconnect
    currently_polling = db[:device].filter(:currently_polling => 1, :worker => poller_name).count
    count = count - currently_polling

    # Don't return more work if this poller is maxed out
    return {} if count < 1

    devices = {}
    # Fetch some devices and mark them as polling
    db.transaction do
      rows = db[:device].filter{ next_poll < Time.now.to_i }
      # Ignore currently_polling value if the last_poll is more than 1000 seconds ago
      rows = rows.filter{Sequel.|({:currently_polling => 0}, (last_poll < Time.now.to_i - 1000))}
      rows = rows.limit(count).for_update
      rows.filter{Sequel.&({:currently_polling => 1}, (last_poll < Time.now.to_i - 1000))}.each do |stale_row|
        $LOG.warn("CORE: Overriding currently_polling for #{stale_row[:device]} (#{poller_name})")
      end

      rows.each do |row|
        devices[row[:device]] = row
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

      data[:interfaces].each do |if_index, oids|
        #$LOG.warn("Device: #{device}  Interface: #{if_index}\n  OIDs: #{oids}")
        # Try updating, and if we don't affect a row, insert instead
        existing = db[:interface].where(:device => oids[:device], :if_index => if_index)
        if existing.update(oids) != 1
          db[:interface].insert(oids)
        end
      end
      data[:cpus].each do |cpu_index, data|
        #$LOG.warn("Device: #{device}  CPU: #{cpu_index}\n  Data: #{data}")
        # Try updating, and if we don't affect a row, insert instead
        existing = db[:cpu].where(:device => data[:device], :cpu_index => cpu_index)
        if existing.update(data) != 1
          db[:cpu].insert(data)
        end
      end

      # Update the device metadata
      next_poll = Time.now.to_i + 100
      db[:device].where(:device => device).update(
        :currently_polling => 0,
        :worker => nil,
        :last_poll_duration => metadata[:last_poll_duration],
        :last_poll_result => metadata[:last_poll_result],
        :last_poll_text => metadata[:last_poll_text],
        :next_poll => next_poll,
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

    API.post('core', '/v1/devices/add', devices, 'CORE', 'new devices')
  end

  def add_devices(settings, db, devices)
    db.disconnect
    devices.each do |device, ip|
      existing = db[:device].where(:device => device)
      if existing.update(:ip => ip) != 1
        $LOG.info("CORE: Adding new device: #{device}")
        db[:device].insert(:device => device, :ip => ip)
      end
    end
    # need error detection
    return true
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
            data[:interfaces].each do |if_index, oids|
              if oids.class == Hash
                oids.symbolize!
              else
                $LOG.warn("Invalid or missing interface data for #{device}: if_index #{if_index}")
                data[:interfaces].delete(if_index)
              end
              required_data = [:device, :if_index, :last_updated, :if_alias, :if_name, :if_mtu,
                               :if_hc_in_octets, :if_hc_out_octets, :if_hc_in_ucast_pkts,
                               :if_hc_out_ucast_pkts, :if_high_speed, :if_admin_status, 
                               :if_admin_status_time, :if_oper_status, :if_oper_status_time,
                               :if_in_discards, :if_in_errors, :if_out_discards, :if_out_errors]
              unless (required_data - oids.keys).empty?
                $LOG.warn("Incomplete OIDs for #{device}: if_index #{if_index}. Missing: #{required_data - oids.keys}")
                data[:interfaces].delete(if_index)
              end
            end
          else
            $LOG.warn("Invalid or missing interfaces received for #{device}")
            data[:interfaces] = {}
          end
          # Validate CPUs
          if data[:cpus].class == Hash
            # Validate CPU data
            data[:cpus].each do |cpu_index, cpu_data|
              if cpu_data.class == Hash
                cpu_data.symbolize!
              else
                $LOG.warn("Invalid CPU data for #{device}: cpu_index #{cpu_index}")
                data[:cpus].delete(cpu_index)
              end
              # Convert utilization to numeric
              cpu_data[:util] = cpu_data[:util].to_i_if_numeric if cpu_data[:util]
              required_data = [:device, :cpu_index, :util, :description, :last_updated]
              unless (required_data - cpu_data.keys).empty?
                $LOG.warn("Invalid CPU for #{device}: cpu_index #{cpu_index}. Missing: #{required_data - cpu_data.keys}")
                data[:cpus].delete(cpu_index)
              end
              unless cpu_data[:util] && cpu_data[:util].is_a?(Numeric)
                $LOG.warn("Invalid or missing CPU utilization for #{device}: cpu_index #{cpu_index}")
                data[:cpus].delete(cpu_index)
              end
              utilization = utilization.to_i_if_numeric
            end
          else
            $LOG.warn("Invalid or missing CPU received for #{device}")
            data[:cpus] = {}
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

  def _interface_map(rows)
    devices = {}
    name_to_index = {}

    rows.each do |row|
      if_index = row[:if_index]
      device = row[:device]

      devices[device] ||= { :interfaces => {} }
      name_to_index[device] ||= {}

      devices[device][:interfaces][if_index] = row
      name_to_index[device][row[:if_name].downcase] = if_index
    end

    return devices, name_to_index
  end

  def _fill_metadata!(devices, settings, name_to_index)
    devices.each do |device,data|
      interfaces = data[:interfaces]
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

end
