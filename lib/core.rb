#!/usr/bin/env ruby
require 'securerandom'

module Core

  def list_devices(settings, db)
    devices = []
    db[:device].select(:device).each { |row| devices.push(row[:device]) }
    return devices
  end


  def get_ints_down(settings, db)
    ints = []
    int_data = db[:interface].filter(
      Sequel.like(:alias, 'sub%') |
      Sequel.like(:alias, 'bb%')
    )
    int_data.exclude(:oper_status => 1).exclude(:type => 'acc').each do |row|
      ints.push Interface.new(device: row[:device], index: row[:index]).populate(row)
    end

    return ints
  end


  def get_ints_saturated(settings, db)
    ints = []
    db[:interface].filter{ (bps_util_in > 90) | (bps_util_out > 90) }.each do |row|
      ints.push Interface.new(device: row[:device], index: row[:index]).populate(row)
    end

    return ints
  end


  def get_ints_discarding(settings, db)
    ints = []
    int_data = db[:interface].where{Sequel.|(
      Sequel.&(
        pps_out > 0, # Prevent div by zero
        discards_out > 20,
        ~Sequel.like(:alias, 'sub%'), # Don't look at sub-interfaces
        discards_out / (discards_out + pps_out).cast(:float) >= 0.01 # Filter out anything discarding <= 1%
      ),
      discards_out > 500 # Also include anything discarding over 500pps
    )}

    int_data.select_all.each do |row|
      ints.push Interface.new(device: row[:device], index: row[:index]).populate(row)
    end

    return ints
  end


  def get_cpus_high(settings, db)
    cpus = []
    db[:cpu].filter{ util > 85 }.each do |row|
      cpus.push CPU.new(device: row[:device], index: row[:index]).populate(row)
    end

    return cpus
  end


  def get_memory_high(settings, db)
    memory = []
    db[:memory].filter{ util > 90 }.each do |row|
      memory.push Memory.new(device: row[:device], index: row[:index]).populate(row)
    end

    return memory
  end


  def get_hw_problems(settings, db)
    hw = { :fans => [], :psus => [], :temps => [] }

    db[:fan].filter(:status => [2,3]).each do |row|
      hw[:fans].push Fan.new(device: row[:device], index: row[:index]).populate(row)
    end
    db[:psu].filter(:status => [2,3]).each do |row|
      hw[:psus].push PSU.new(device: row[:device], index: row[:index]).populate(row)
    end
    db[:temperature].filter(:status => 2).each do |row|
      hw[:temps].push Temperature.new(device: row[:device], index: row[:index]).populate(row)
    end

    return hw
  end


  def get_alarms(settings, db)
    devices = []
    device_data = db[:device].exclude(
      (Sequel.expr(:yellow_alarm => 2) | Sequel.expr(:yellow_alarm => nil)) &
      (Sequel.expr(:red_alarm => 2) | Sequel.expr(:red_alarm => nil))
    )
    device_data.select_all.each do |row|
      devices.push(Device.new(row[:device]).populate(row))
    end

    return devices
  end


  def get_poller_failures(settings, db)
    devices = []
    db[:device].filter(:last_poll_result => 1).each do |row|
      devices.push(Device.new(row[:device]).populate(row))
    end

    return devices
  end


  def get_interface(settings, db, device, index: nil, name: nil)
    if index
      row = db[:interface].where(:device => device, :index => index).all[0]
    elsif name
      row = db[:interface].where(:device => device)
      row = row.where(Sequel.function(:lower, :name) => name.downcase).all[0]
    else
      row = nil
    end

    if row
      return Interface.new(device: row[:device], index: row[:index]).populate(row)
    else
      return {}
    end
  end


  def get_interfaces(settings, db, device)
    ints = {}
    db[:interface].where(:device => device).each do |row|
      index = row[:index].to_i
      ints[index] = Interface.new(device: row[:device], index: index).populate(row)
    end
    return ints
  end


  def get_cpu(settings, db, device, index)
    row = db[:cpu].where(:device => device, :index => index.to_s).all[0]
    if row
      return CPU.new(device: row[:device], index: row[:index]).populate(row)
    else
      return {}
    end
  end


  def get_cpus(settings, db, device)
    cpus = {}
    db[:cpu].where(:device => device).each do |row|
      index = row[:index].to_i
      cpus[index] = CPU.new(device: row[:device], index: index).populate(row)
    end
    return cpus
  end


  def get_fan(settings, db, device, index)
    row = db[:fan].where(:device => device, :index => index.to_s).all[0]
    if row
      return Fan.new(device: row[:device], index: row[:index]).populate(row)
    else
      return {}
    end
  end


  def get_fans(settings, db, device)
    fans = {}
    db[:fan].where(:device => device).each do |row|
      index = row[:index].to_i
      fans[index] = Fan.new(device: row[:device], index: index).populate(row)
    end
    return fans
  end


  def get_memory(settings, db, device, index)
    row = db[:memory].where(:device => device, :index => index.to_s).all[0]
    if row
      return Memory.new(device: row[:device], index: row[:index]).populate(row)
    else
      return {}
    end
  end


  def get_memories(settings, db, device)
    memories = {}
    db[:memory].where(:device => device).each do |row|
      index = row[:index].to_i
      memories[index] = Memory.new(device: row[:device], index: index).populate(row)
    end
    return memories
  end


  def get_psu(settings, db, device, index)
    row = db[:psu].where(:device => device, :index => index.to_s).all[0]
    if row
      return PSU.new(device: row[:device], index: row[:index]).populate(row)
    else
      return {}
    end
  end


  def get_psus(settings, db, device)
    psus = {}
    db[:psu].where(:device => device).each do |row|
      index = row[:index].to_i
      psus[index] = PSU.new(device: row[:device], index: index).populate(row)
    end
    return psus
  end


  def get_temperature(settings, db, device, index)
    row = db[:temperature].where(:device => device, :index => index.to_s).all[0]
    if row
      return Temperature.new(device: row[:device], index: row[:index]).populate(row)
    else
      return {}
    end
  end


  def get_temperatures(settings, db, device)
    temperatures = {}
    db[:temperature].where(:device => device).each do |row|
      index = row[:index].to_i
      temperatures[index] = Temperature.new(device: row[:device], index: index).populate(row)
    end
    return temperatures
  end


  def get_device(settings, db, device)
    db[:device].where(:device => device).each do |row|
      return Device.new(row[:device]).populate(row) || {}
    end
    return {}
  end


  def fetch_poll(settings, db, count, poller)
    db.disconnect
    currently_polling = db[:device].filter{Sequel.&(
      {:currently_polling => 1, :worker => poller},
      last_poll > Time.now.to_i - 1800,
    )}.count
    count = count - currently_polling

    # Don't return more work if this poller is maxed out
    return {} if count < 1

    devices = {}
    # Fetch some devices and mark them as polling
    db.transaction do
      rows = db[:device].filter{ next_poll < Time.now.to_i }
      rows = rows.filter{Sequel.|({:currently_polling => 0}, (last_poll < Time.now.to_i - 1800))}
      rows = rows.order(:next_poll)
      rows = rows.limit(count).for_update

      rows.each do |row|
        uuid = SecureRandom.uuid
        devices[row[:device]] = uuid
        $LOG.warn("CORE: Overriding currently_polling for #{row[:device]} (#{poller})") if row[:currently_polling] == 1
        $LOG.info("CORE: Sending device #{row[:device]} to #{poller} (#{uuid})")
        device_row = db[:device].where(:device => row[:device])
        device_row.update(
          :currently_polling => 1,
          :poller_uuid => uuid,
          :worker => poller,
          :last_poll => Time.now.to_i,
        )
      end
    end
    return devices
  end


  def post_device(settings, db, device)
    db.disconnect
    $LOG.info("CORE: Receiving device #{device.name} from #{device.worker} (#{device.poller_uuid})")
    begin
      if device.poller_uuid == db[:device].where(:device => device.name).get(:poller_uuid)
        device.save(db)
        db[:device].where(:device => device.name).update(:currently_polling => 0)
        $LOG.info("CORE: Saved device #{device.name} from #{device.worker}")
      else
        $LOG.error("CORE: Invalid poller_uuid from #{device.worker} - #{device.name}")
      end
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

    API.post('core', '/v2/devices/replace', devices, 'CORE', 'new devices')
  end


  def add_devices(settings, db, new_devices, replace: false)
    db.disconnect

    new_devices.each do |device, ip|
      Device.new(device, poll_ip: ip).save(db)
      $LOG.warn("CORE: Added device #{device}: #{ip}")
    end

    if replace
      # Delete any devices that weren't provided
      existing = db[:device].select(:device, :ip).to_hash(:device).keys
      (existing - new_devices.keys).each do |device|
        Device.new(device).delete(db)
        $LOG.warn("CORE: Deleted device #{device}; not in new device set")
      end
    end
    # need error detection
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
      name_to_index[device][row[:name].downcase] = index
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
        oids[:alias].to_s.match(/__[a-zA-Z0-9\-_]+__/) do |neighbor|
          interfaces[index][:neighbor] = neighbor.to_s.gsub('__','')
        end

        time_since_poll = Time.now.to_i - oids[:last_updated]
        oids[:stale] = time_since_poll if time_since_poll > settings['stale_timeout']

        if oids[:pps_out] && oids[:discards_out]
          oids[:discards_out_pct] = '%.2f' % (oids[:discards_out].to_f / (oids[:pps_out] + oids[:discards_out]) * 100)
        end

        # Populate 'link_type' value (Backbone, Access, etc...)
        if type = oids[:alias].match(/^([a-z]+)(__|\[)/)
          type = type[1]
        else
          type = 'unknown'
        end
        oids[:link_type] = settings['link_types'][type]
        if type == 'sub'
          oids[:is_child] = true
          # This will return po1 from sub[po1]__gar-k11u1-dist__g1/47
          parent = oids[:alias][/\[[a-zA-Z0-9\/-]+\]/].gsub(/(\[|\])/, '')
          if parent && parent_index = name_to_index[device][parent.downcase]
            interfaces[parent_index][:is_parent] = true
            interfaces[parent_index][:children] ||= []
            interfaces[parent_index][:children] << index
            oids[:my_parent] = parent_index
          end
          oids[:my_parent_name] = parent.gsub('po','Po')
        end

        oids[:oper_status] == 1 ? oids[:link_up] = true : oids[:link_up] = false
      end
    end
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
