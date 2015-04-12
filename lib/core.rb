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

    (devices, name_to_index) = _device_map(:interfaces => interfaces)
    _fill_metadata!(devices, settings, name_to_index)

    # Delete the interface from the hash if its parent is present, to reduce clutter
    devices.each do |device,components|
      ints = components[:interfaces]
      ints.delete_if { |index,oids| oids[:my_parent] && ints[oids[:my_parent]] }
    end
    return devices
  end


  def get_ints_saturated(settings, db)
    interfaces = db[:interface].filter{ (bps_in_util > 90) | (bps_out_util > 90) }

    (devices, name_to_index) = _device_map(:interfaces => interfaces)
    _fill_metadata!(devices, settings, name_to_index)
    return devices
  end


  def get_ints_discarding(settings, db)
    interfaces = db[:interface].filter{Sequel.|(
      Sequel.&(
        pps_out > 0, # Prevent div by zero
        discards_out > 20,
        ~Sequel.like(:if_alias, 'sub%'), # Don't look at sub-interfaces
        discards_out / (discards_out + pps_out).cast(:float) >= 0.01 # Filter out anything discarding <= 1%
      ),
      discards_out > 500 # Also include anything discarding over 500pps
    )}
    interfaces = interfaces.order(:discards_out).reverse

    (devices, name_to_index) = _device_map(:interfaces => interfaces)
    _fill_metadata!(devices, settings, name_to_index)
    return devices
  end


  def get_interface(settings, db, device, index=nil)
    if index
      db[:interface].where(:device => device, :index => index).all[0] || {}
    else
      db[:interface].where(:device => device).all
    end
  end


  def get_cpu(settings, db, device, index=nil)
    if index
      db[:cpu].where(:device => device, :index => index).all[0] || {}
    else
      db[:cpu].where(:device => device).all
    end
  end


  def get_fan(settings, db, device, index=nil)
    if index
      db[:fan].where(:device => device, :index => index).all[0] || {}
    else
      db[:fan].where(:device => device).all
    end
  end


  def get_memory(settings, db, device, index=nil)
    if index
      db[:memory].where(:device => device, :index => index).all[0] || {}
    else
      db[:memory].where(:device => device).all
    end
  end


  def get_psu(settings, db, device, index=nil)
    if index
      db[:psu].where(:device => device, :index => index).all[0] || {}
    else
      db[:psu].where(:device => device).all
    end
  end


  def get_temperature(settings, db, device, index=nil)
    if index
      db[:temperature].where(:device => device, :index => index).all[0] || {}
    else
      db[:temperature].where(:device => device).all
    end
  end


  def get_device(settings, db, device)
    db[:device].where(:device => device).all[0]
  end


  def get_cpus_high(settings, db)
    cpus = db[:cpu].filter{ util > 85 }

    (devices, name_to_index) = _device_map(:cpus => cpus)
    return devices
  end


  def get_memory_high(settings, db)
    memory = db[:memory].filter{ util > 90 }

    (devices, name_to_index) = _device_map(:memory => memory)
    return devices
  end


  def get_hw_problems(settings, db)
    temperatures = db[:temperature].filter(:status => 2)
    psus = db[:psu].filter(:status => [2,3])
    fans = db[:fan].filter(:status => [2,3])

    (devices, name_to_index) = _device_map(:temperatures => temperatures,
                                           :psus => psus,
                                           :fans => fans,
                                          )
    return devices
  end


  def get_alarms(settings, db)
    devicedata = db[:device].exclude(
      (Sequel.expr(:yellow_alarm => 2) | Sequel.expr(:yellow_alarm => nil)) &
      (Sequel.expr(:red_alarm => 2) | Sequel.expr(:red_alarm => nil))
    )

    (devices, name_to_index) = _device_map(:devicedata => devicedata)
    return devices
  end


  def get_poller_failures(settings, db)
    failures = db[:device].filter(:last_poll_result => 1)

    (devices, name_to_index) = _device_map(:devicedata => failures)
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
      rows = rows.order(:next_poll)
      rows = rows.limit(count).for_update

      rows.each do |row|
        devices[row[:device]] = row[:ip]
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


  def post_device(settings, db, device)
    db.disconnect
    $LOG.info("CORE: Received device #{device.name} from #{device.worker}")
    begin
      device.save(db)
    rescue Sequel::PoolTimeout => e
      $LOG.error("CORE: SQL error! \n#{e}")
    end
    return 200
  end

  def post_interface(settings, db, int)
    db.disconnect
    $LOG.info("CORE: Received if #{int.index} (#{int.name}) on #{int.device} from #{int.worker}")
    begin
      int.save(db)
    rescue Sequel::PoolTimeout => e
      $LOG.error("CORE: SQL error! \n#{e}")
    end
    return 200
  end

  def post_cpu(settings, db, cpu)
    db.disconnect
    $LOG.info("CORE: Received cpu #{cpu.index} on #{cpu.device} from #{cpu.worker}")
    begin
      cpu.save(db)
    rescue Sequel::PoolTimeout => e
      $LOG.error("CORE: SQL error! \n#{e}")
    end
    return 200
  end

  def post_fan(settings, db, fan)
    db.disconnect
    $LOG.info("CORE: Received fan #{fan.index} on #{fan.device} from #{fan.worker}")
    begin
      fan.save(db)
    rescue Sequel::PoolTimeout => e
      $LOG.error("CORE: SQL error! \n#{e}")
    end
    return 200
  end

  def post_memory(settings, db, memory)
    db.disconnect
    $LOG.info("CORE: Received memory #{memory.index} on #{memory.device} from #{memory.worker}")
    begin
      memory.save(db)
    rescue Sequel::PoolTimeout => e
      $LOG.error("CORE: SQL error! \n#{e}")
    end
    return 200
  end

  def post_psu(settings, db, psu)
    db.disconnect
    $LOG.info("CORE: Received psu #{psu.index} on #{psu.device} from #{psu.worker}")
    begin
      psu.save(db)
    rescue Sequel::PoolTimeout => e
      $LOG.error("CORE: SQL error! \n#{e}")
    end
    return 200
  end

  def post_temperature(settings, db, temp)
    db.disconnect
    $LOG.info("CORE: Received temp #{temp.index} on #{temp.device} from #{temp.worker}")
    begin
      temp.save(db)
    rescue Sequel::PoolTimeout => e
      $LOG.error("CORE: SQL error! \n#{e}")
    end
    return 200
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


  def _device_map(data={})
    data[:cpus] ||= {}
    data[:fans] ||= {}
    data[:psus] ||= {}
    data[:memory] ||= {}
    data[:devicedata] ||= {}
    data[:interfaces] ||= {}
    data[:temperatures] ||= {}

    devices = {}
    name_to_index = {}

    data[:devicedata].each do |row|
      devices[row[:device]] = { :devicedata => row }
    end
    data[:interfaces].each do |row|
      index = row[:index]
      device = row[:device]

      devices[device] ||= {}
      devices[device][:interfaces] ||= {}
      name_to_index[device] ||= {}

      devices[device][:interfaces][index] = row
      name_to_index[device][row[:if_name].downcase] = index
    end
    data[:cpus].each do |row|
      index = row[:index]
      device = row[:device]

      devices[device] ||= {}
      devices[device][:cpus] ||= {}
      devices[device][:cpus][index] = row
    end
    data[:memory].each do |row|
      index = row[:index]
      device = row[:device]

      devices[device] ||= {}
      devices[device][:memory] ||= {}
      devices[device][:memory][index] = row
    end
    data[:temperatures].each do |row|
      index = row[:index]
      device = row[:device]

      devices[device] ||= {}
      devices[device][:temperatures] ||= {}
      devices[device][:temperatures][index] = row
    end
    data[:psus].each do |row|
      index = row[:index]
      device = row[:device]

      devices[device] ||= {}
      devices[device][:psus] ||= {}
      devices[device][:psus][index] = row
    end
    data[:fans].each do |row|
      index = row[:index]
      device = row[:device]

      devices[device] ||= {}
      devices[device][:fans] ||= {}
      devices[device][:fans][index] = row
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

        if oids[:pps_out] && oids[:discards_out]
          oids[:discards_out_pct] = '%.2f' % (oids[:discards_out].to_f / (oids[:pps_out] + oids[:discards_out]) * 100)
        end

        # Populate 'link_type' value (Backbone, Access, etc...)
        if type = oids[:if_alias].match(/^([a-z]+)(__|\[)/)
          type = type[1]
        else
          type = 'unknown'
        end
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
              required_data = [:device, :index, :last_updated, :if_name, :if_mtu, :if_type,
                               :if_hc_in_octets, :if_hc_out_octets, :if_hc_in_ucast_pkts,
                               :if_hc_out_ucast_pkts, :if_high_speed, :if_admin_status,
                               :if_admin_status_time, :if_oper_status, :if_oper_status_time,
                               :if_in_discards, :if_in_errors, :if_out_discards, :if_out_errors]
              unless (required_data - oids.keys).empty?
                $LOG.warn("CORE: Incomplete OIDs for #{device}: #{oids[:if_name]} (#{index}). Missing: #{required_data - oids.keys}")
                data[:interfaces].delete(index)
              end
              required_data.each do |oid|
                if oids[oid].to_s.empty?
                  $LOG.warn("CORE: Missing #{oid} for #{device}: #{oids[:if_name]} (#{index})")
                  data[:interfaces].delete(index)
                end
              end
              unless (oids[:if_hc_in_octets] =~ /^[0-9]+$/)
                $LOG.warn("CORE: Invalid octet value for interface #{oids[:if_name]} on device #{device}: index #{index}.")
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
          # Validate Temperature
          if data[:temperature].class == Hash
            # Validate Temperature data
            data[:temperature].each do |index, temp_data|
              if temp_data.class == Hash
                temp_data.symbolize!
              else
                $LOG.warn("Invalid Temperature data for #{device}: index #{index}")
                data[:temperature].delete(index)
              end
              # Convert utilization to numeric
              temp_data[:temperature] = temp_data[:temperature].to_i_if_numeric if temp_data[:temperature]
              required_data = [:device, :index, :temperature, :description, :last_updated, :status, :status_text]
              unless (required_data - temp_data.keys).empty?
                $LOG.warn("Invalid Temperature data for #{device}: index #{index}. Missing: #{required_data - temp_data.keys}")
                data[:temperature].delete(index)
              end
              unless temp_data[:temperature] && temp_data[:temperature].is_a?(Numeric)
                $LOG.warn("Invalid or missing Temperature for #{device}: index #{index}")
                data[:temperature].delete(index)
              end
            end
          else
            $LOG.warn("Invalid or missing Temperature data received for #{device}")
            data[:temperature] = {}
          end
          # Validate PSUs
          if data[:psu].class == Hash
            # Validate PSU data
            data[:psu].each do |index, psu_data|
              if psu_data.class == Hash
                psu_data.symbolize!
              else
                $LOG.warn("Invalid PSU data for #{device}: index #{index}")
                data[:psu].delete(index)
              end
              required_data = [:device, :index, :description, :last_updated, :status, :status_text]
              unless (required_data - psu_data.keys).empty?
                $LOG.warn("Invalid PSUs data for #{device}: index #{index}. Missing: #{required_data - psu_data.keys}")
                data[:psu].delete(index)
              end
            end
          else
            $LOG.warn("Invalid or missing PSUs data received for #{device}")
            data[:psu] = {}
          end
          # Validate Fans
          if data[:fan].class == Hash
            # Validate Fan data
            data[:fan].each do |index, fan_data|
              if fan_data.class == Hash
                fan_data.symbolize!
              else
                $LOG.warn("Invalid Fan data for #{device}: index #{index}")
                data[:fan].delete(index)
              end
              required_data = [:device, :index, :description, :last_updated, :status, :status_text]
              unless (required_data - fan_data.keys).empty?
                $LOG.warn("Invalid Fan data for #{device}: index #{index}. Missing: #{required_data - fan_data.keys}")
                data[:fan].delete(index)
              end
            end
          else
            $LOG.warn("Invalid or missing Fans data received for #{device}")
            data[:fan] = {}
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


  def self.start_cron(settings)
    $LOG.info("POLLER: Starting cron poke task")
    pidfile = 'proc.lock'
    begin
      if File.exists?(pidfile)
        pid = File.read(pidfile).to_i
        $LOG.warn("POLLER: Killing process #{pid}")
        Process.kill(15, pid)
      end
    rescue Errno::ESRCH
    end

    pid = spawn "./cron.sh"
    Process.detach(pid)
    File.open(pidfile, 'w') { |f| f.write(pid) }
  end


end
