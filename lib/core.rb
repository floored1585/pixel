#
# Pixel is an open source network monitoring system
# Copyright (C) 2016 all Pixel contributors!
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#!/usr/bin/env ruby
require 'securerandom'

module Core

  def list_devices(db)
    devices = []
    db[:device].select(:device).each { |row| devices.push(row[:device]) }
    return devices
  end


  def get_ints_down(db)
    #start = Time.now
    ints = []
    int_data = db[:interface].filter(
      Sequel.like(:description, 'sub%') |
      Sequel.like(:description, 'bb%')
    )
    int_data = int_data.exclude(:oper_status => 1).exclude(:type => 'acc').
      natural_join(:component)

    int_data.each do |row|
      ints.push Interface.new(device: row[:device], index: row[:index]).populate(row)
    end
    #puts "get_ints_down: #{'%.2f' % (Time.now - start) }s"

    return ints
  end


  def get_ints_saturated(db, util: 90, speed: nil)
    #start = Time.now
    ints = []
    rows = db[:interface].filter{ (bps_util_in > util) | (bps_util_out > util) }.
      natural_join(:component)
    rows = rows.where(:speed => speed) if speed
    rows.each do |row|
      ints.push Interface.new(device: row[:device], index: row[:index]).populate(row)
    end
    #puts "get_ints_saturated: #{'%.2f' % (Time.now - start) }s"

    return ints
  end


  def get_ints_discarding(db)
    #start = Time.now
    ints = []
    int_data = db[:interface].natural_join(:component).where{ discards_out > 500 }

    int_data.select_all.each do |row|
      ints.push Interface.new(device: row[:device], index: row[:index]).populate(row)
    end
    #puts "get_ints_discarding: #{'%.2f' % (Time.now - start) }s"

    return ints
  end


  def get_cpus_high(db)
    #start = Time.now
    cpus = []
    db[:cpu].filter{ util > 85 }.natural_join(:component).each do |row|
      cpus.push CPU.new(device: row[:device], index: row[:index]).populate(row)
    end
    #puts "get_cpus_high: #{'%.2f' % (Time.now - start) }s"

    return cpus
  end


  def get_memory_high(db)
    #start = Time.now
    memory = []
    db[:memory].filter{ util > 90 }.natural_join(:component).each do |row|
      memory.push Memory.new(device: row[:device], index: row[:index]).populate(row)
    end
    #puts "get_memory_high: #{'%.2f' % (Time.now - start) }s"

    return memory
  end


  def get_hw_problems(db)
    #start = Time.now
    hw = { :fans => [], :psus => [], :temps => [] }

    db[:fan].where(:status => [2,3]).natural_join(:component).each do |row|
      hw[:fans].push Fan.new(device: row[:device], index: row[:index]).populate(row)
    end
    db[:psu].where(:status => [2,3]).natural_join(:component).each do |row|
      hw[:psus].push PSU.new(device: row[:device], index: row[:index]).populate(row)
    end
    db[:temperature].where(:status => 2).natural_join(:component).each do |row|
      hw[:temps].push Temperature.new(device: row[:device], index: row[:index]).populate(row)
    end
    #puts "get_hw_problems: #{'%.2f' % (Time.now - start) }s"

    return hw
  end


  def get_alarms(db)
    #start = Time.now
    devices = []
    device_data = db[:device].exclude(
      (Sequel.expr(:yellow_alarm => 2) | Sequel.expr(:yellow_alarm => nil)) &
      (Sequel.expr(:red_alarm => 2) | Sequel.expr(:red_alarm => nil))
    )
    device_data.select_all.each do |row|
      devices.push(Device.new(row[:device]).populate(row))
    end
    #puts "get_alarms: #{'%.2f' % (Time.now - start) }s"

    return devices
  end


  def get_poller_failures(db)
    #start = Time.now
    devices = []
    db[:device].filter(:last_poll_result => 1).each do |row|
      devices.push(Device.new(row[:device]).populate(row))
    end
    #puts "get_poller_failures: #{'%.2f' % (Time.now - start) }s"

    return devices
  end


  def get_interface(db, device, index: nil, name: nil)
    if index
      row = db[:interface].where(:device => device, :index => index.to_s).
        natural_join(:component).first
    elsif name
      row = db[:interface].where(:device => device).
        where(Sequel.function(:lower, :name) => name.downcase).
        natural_join(:component).first
    else
      row = nil
    end

    if row
      return Interface.new(device: row[:device], index: row[:index]).populate(row)
    else
      return {}
    end
  end


  def get_device(db, device)
    db[:device].where(:device => device).each do |row|
      return Device.new(row[:device]).populate(row) || {}
    end
    return {}
  end


  def fetch_poll(db, count, poller)
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
      rows = db[:device].filter(:enable_polling => true)
      rows = rows.filter{ next_poll < Time.now.to_i }
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


  def post_config(db, config)
    db.disconnect
    $LOG.info("CORE: Receiving config.")
    begin
      response = config.save(db).class == Config ? 200 : 400
      $LOG.info("CORE: Saved config.")
    rescue Sequel::PoolTimeout => e
      $LOG.error("CORE: SQL error! \n#{e}")
    end
    return response
  end


  def post_instance(db, instance)
    db.disconnect
    $LOG.info("CORE: Receiving instance #{instance.hostname}.")
    begin
      instance.set_master(true) if instance.core? && Instance.fetch_from_db(db: db, master: true).empty?
      response = instance.save(db).class == Instance ? 200 : 400
      $LOG.info("CORE: Saved instance #{instance.hostname}.")
    rescue Sequel::PoolTimeout => e
      $LOG.error("CORE: SQL error! \n#{e}")
    end
    return response
  end


  def post_device(db, device)
    db.disconnect
    uuid = device.poller_uuid
    $LOG.info("CORE: Receiving device #{device.name} from #{device.worker} (#{uuid})")
    begin
      # Only process the data if the poller_uuid is empty (post not from a poller) or
      #   matches the database value.  This won't be needed after HTTP gem is removed so
      #   we can control timeouts properly.
      if uuid.empty? || uuid == db[:device].where(:device => device.name).get(:poller_uuid)
        response = device.save(db).class == Device ? 200 : 400
        db[:device].where(:device => device.name).update(:currently_polling => 0)
        $LOG.info("CORE: Saved device #{device.name} from #{device.worker} (#{uuid})")
      else
        $LOG.error("CORE: Received invalid poller_uuid (#{uuid}) for device #{device.name} from #{device.worker}")
      end
    rescue Sequel::PoolTimeout => e
      $LOG.error("CORE: SQL error! \n#{e}")
    end
    return response
  end

  def post_interface(db, int)
    db.disconnect
    $LOG.info("CORE: Received if #{int.index} (#{int.name}) on #{int.device} from #{int.worker}")
    begin
      int.save(db)
    rescue Sequel::PoolTimeout => e
      $LOG.error("CORE: SQL error! \n#{e}")
    end
    return 200
  end

  def post_cpu(db, cpu)
    db.disconnect
    $LOG.info("CORE: Received cpu #{cpu.index} on #{cpu.device} from #{cpu.worker}")
    begin
      cpu.save(db)
    rescue Sequel::PoolTimeout => e
      $LOG.error("CORE: SQL error! \n#{e}")
    end
    return 200
  end

  def post_fan(db, fan)
    db.disconnect
    $LOG.info("CORE: Received fan #{fan.index} on #{fan.device} from #{fan.worker}")
    begin
      fan.save(db)
    rescue Sequel::PoolTimeout => e
      $LOG.error("CORE: SQL error! \n#{e}")
    end
    return 200
  end

  def post_memory(db, memory)
    db.disconnect
    $LOG.info("CORE: Received memory #{memory.index} on #{memory.device} from #{memory.worker}")
    begin
      memory.save(db)
    rescue Sequel::PoolTimeout => e
      $LOG.error("CORE: SQL error! \n#{e}")
    end
    return 200
  end

  def post_psu(db, psu)
    db.disconnect
    $LOG.info("CORE: Received psu #{psu.index} on #{psu.device} from #{psu.worker}")
    begin
      psu.save(db)
    rescue Sequel::PoolTimeout => e
      $LOG.error("CORE: SQL error! \n#{e}")
    end
    return 200
  end

  def post_temperature(db, temp)
    db.disconnect
    $LOG.info("CORE: Received temp #{temp.index} on #{temp.device} from #{temp.worker}")
    begin
      temp.save(db)
    rescue Sequel::PoolTimeout => e
      $LOG.error("CORE: SQL error! \n#{e}")
    end
    return 200
  end


  def populate_device_table(db)
    db.disconnect
    devices = {}

    # Load from file TODO: move this to the config somehow
    device_file = 'config/hosts.yaml'

    if File.exists?(device_file)
      devices = YAML.load_file(File.join(APP_ROOT, device_file)) || {}
    else
      $LOG.error("CORE: Error populating devices from file: File not found: #{device_file}")
    end
    $LOG.info("CORE: Importing #{devices.size} devices from file: #{device_file}")

    API.post(
      src: 'core',
      dst: 'core',
      resource: '/v2/devices/replace',
      what: "new devices",
      data: devices,
    )
  end


  def add_devices(db, new_devices, replace: false)
    db.disconnect

    new_devices.each do |device, ip|
      Device.new(device, poll_ip: ip).save(db)
      $LOG.warn("CORE: Updated device #{device}: #{ip}")
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


  def _fill_metadata!(devices, config, name_to_index)
    devices.each do |device,data|
      interfaces = data[:interfaces] || {}
      interfaces.each do |index,oids|
        # Populate 'neighbor' value
        oids[:description].to_s.match(/__[a-zA-Z0-9\-_]+__/) do |neighbor|
          interfaces[index][:neighbor] = neighbor.to_s.gsub('__','')
        end

        time_since_poll = Time.now.to_i - oids[:last_updated]
        oids[:stale] = time_since_poll if time_since_poll > config.settings['stale_timeout'].value

        if oids[:pps_out] && oids[:discards_out]
          oids[:discards_out_pct] = '%.2f' % (oids[:discards_out].to_f / (oids[:pps_out] + oids[:discards_out]) * 100)
        end

        # Populate 'link_type' value (Backbone, Access, etc...)
        # TODO: This stuff (regex and hash) should be in the config somewhere
        link_types = {
          bb: 'Backbone',
          acc: 'Access',
          sub: 'Child',
          trn: 'Transit',
          exc: 'Exchange',
          p2p: 'P2P',
          unknown: 'Unknown',
        }
        if type = oids[:description].match(/^([a-z]+)(__|\[)/)
          type = type[1]
        else
          type = 'unknown'
        end
        oids[:link_type] = link_types[type]
        if type == 'sub'
          oids[:is_child] = true
          # This will return po1 from sub[po1]__gar-k11u1-dist__g1/47
          parent = oids[:description][/\[[a-zA-Z0-9\/-]+\]/].gsub(/(\[|\])/, '')
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


end
