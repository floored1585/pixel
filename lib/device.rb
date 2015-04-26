# device.rb
require 'logger'
require 'snmp'
require_relative 'api'
require_relative 'influx'
require_relative 'configfile'
require_relative 'core_ext/object'
require_relative 'interface'
require_relative 'cpu'
require_relative 'fan'
require_relative 'memory'
require_relative 'psu'
require_relative 'temperature'

$LOG ||= Logger.new(STDOUT)

class Device


  def self.fetch(device, opts={})
    # Get the device via API
    obj = API.get(
      src: 'device',
      dst: 'core',
      resource: "/v2/device/#{device}",
      what: "device #{device}"
    )
    return nil unless obj.class == Device

    valid_opts = [ :all, :interfaces, :cpus, :fans, :memory, :psus, :temperatures ]
    # Run populate only if one of the valid_opts are present (if we
    #   were asked to fetch components as well)
    obj.populate(nil, opts) unless (valid_opts - opts.keys) == valid_opts
    return obj
  end


  def initialize(name, poll_ip: nil, poll_cfg: nil)

    # required
    @name = name

    # optional
    @poll_ip = poll_ip
    @poll_cfg = poll_cfg || Configfile.retrieve['poller']

    @interfaces = {}
    @cpus = {}
    @fans = {}
    @memory = {}
    @psus = {}
    @temps = {}

  end

  
  def name
    @name
  end


  def poll_ip
    @poll_ip
  end


  def poller_uuid
    @poller_uuid || ''
  end


  # Return an array containing all Interface objects in the device
  def interfaces
    @interfaces
  end


  # Return an array containing all CPU objects in the device
  def cpus
    @cpus
  end


  # Return an array containing all Fan objects in the device
  def fans
    @fans
  end


  # Return an array containing all Memory objects in the device
  def memory
    @memory
  end


  # Return an array containing all PSU objects in the device
  def psus
    @psus
  end


  # Return an array containing all Temperature objects in the device
  def temps
    @temps
  end


  def worker
    @worker.to_s
  end


  def uptime
    @uptime.to_i
  end


  def bps_out
    bps_out = 0
    @interfaces.each { |index,int| bps_out += int.bps_out if int.physical? }
    return bps_out
  end


  def pps_out
    pps_out = 0
    @interfaces.each { |index,int| pps_out += int.pps_out if int.physical? }
    return pps_out
  end


  def discards_out
    discards_out = 0
    @interfaces.each { |index,int| discards_out += int.discards_out if int.physical? }
    return discards_out
  end


  def errors_out
    errors_out = 0
    @interfaces.each { |index,int| errors_out += int.errors_out if int.physical? }
    return errors_out
  end


  def vendor
    @vendor.to_s
  end


  def sw_descr
    @sw_descr.to_s
  end


  def sw_version
    @sw_version.to_s
  end


  def hw_model
    @hw_model.to_s
  end


  def red_alarm
    return true if @red_alarm && @red_alarm != 2
    return false
  end


  def yellow_alarm
    return true if @yellow_alarm && @yellow_alarm != 2
    return false
  end


  def get_interface(name: nil, index: nil)
    # Return nil unless either a name or index was passed
    return nil unless name || index

    return @interfaces[index.to_i_if_numeric] if index
    @interfaces.each { |index, int| return int if name.downcase == int.name.downcase }

    return nil # If nothing matched
  end


  def get_children(parent_name: nil, parent_index: nil)
    # Return nil unless either a name or index was passed and they match something
    return [] unless parent_name || parent_index
    return [] unless parent = @interfaces[parent_index.to_i] || get_interface(name: parent_name)

    children = []
    @interfaces.each do |index, int|
      next unless int.parent_name
      children.push(int) if int.parent_name.downcase == parent.name.downcase
    end

    return children
  end


  def poll(worker:, uuid:, poll_ip: nil, poll_cfg: nil, items: [ :all ])
    @worker = worker
    @poller_uuid = uuid

    # If poll_ip or poll_cfg were passed in, update them
    @poll_ip = poll_ip if poll_ip
    @poll_cfg = poll_cfg if poll_cfg

    # Return if we don't have everything needed to poll
    unless @poll_cfg
      $LOG.error("Device<#{@name}>: Can't execute poll with no poll_cfg")
      return nil
    end
    unless @poll_ip
      $LOG.error("Device<#{@name}>: Can't execute poll with no poll_ip")
      return nil
    end

    # Exception handling for SNMP errors
    begin
      session = _open_poll_session

      start = Time.now.to_i

      # Poll the device items that were requested (component defaults to :all)
      dev_time = _poll_device_info(session)
      int_time = _poll_interfaces(session) if items.include?(:all) || items.include?(:interfaces)
      temp_time = _poll_temperatures(session) if items.include?(:all) || items.include?(:temperatures)
      mem_time = _poll_memory(session) if items.include?(:all) || items.include?(:memory)
      cpu_time = _poll_cpus(session) if items.include?(:all) || items.include?(:cpus)
      psu_time = _poll_psus(session) if items.include?(:all) || items.include?(:psus)
      fan_time = _poll_fans(session) if items.include?(:all) || items.include?(:fans)

      total_time = Time.now.to_i - start

      # Post-processing

      processing_time = _process_interfaces if items.include?(:all) || items.include?(:interfaces)

    rescue RuntimeError, ArgumentError => e
      $LOG.error("POLLER: Error encountered while polling #{@name}: #{e}")
      @next_poll = Time.now.to_i + 100
      @last_poll_result = 1
      @last_poll_text = e.to_s

      # Unset components so they aren't erased
      @interfaces = {}
      @cpus = {}
      @fans = {}
      @memory = {}
      @psus = {}
      @temps = {}

      return nil
    ensure
      session.close if session
    end

    @last_poll_result = 0
    @last_poll_text = "Success: #{dev_time},#{int_time},#{temp_time},#{mem_time},#{cpu_time},#{psu_time},#{fan_time},#{total_time},#{processing_time}"
    @last_poll_duration = total_time
    @currently_polling = 0

    return self
  end


  # populate is called by #fetch to get components and by #json_create to fill in
  #   device data and components.
  def populate(data, opts={})

    # directly passed data will never be overwritten by data passed via opts hash
    data = JSON.load(data) if data.class == String # To allow for raw JSON as well as objects

    # If data was passed in, update the device
    if data
      # Required in order to accept symbol and non-symbol keys
      data = data.symbolize

      @interfaces = data[:interfaces] || {}
      # Convert keys to integers for @interface
      @interfaces = Hash[@interfaces.map{|key,int|[ key.to_i, int ]}]
      @cpus = data[:cpus] || {}
      @fans = data[:fans] || {}
      @memory = data[:memory] || {}
      @psus = data[:psus] || {}
      @temps = data[:temps] || {}

      # Return if the device wasn't found
      return nil unless data[:device]

      # Update instance variables
      @poll_ip = data[:ip]
      @last_poll = data[:last_poll].to_i_if_numeric
      @next_poll = data[:next_poll].to_i_if_numeric
      @last_poll_duration = data[:last_poll_duration].to_i_if_numeric
      @last_poll_result = data[:last_poll_result].to_i_if_numeric
      @last_poll_text = data[:last_poll_text]
      @currently_polling = data[:currently_polling].to_i_if_numeric
      @worker = data[:worker]
      @sys_descr = data[:sys_descr]
      @vendor = data[:vendor]
      @sw_descr = data[:sw_descr]
      @sw_version = data[:sw_version]
      @hw_model = data[:hw_model]
      @uptime = data[:uptime].to_i_if_numeric
      @yellow_alarm = data[:yellow_alarm].to_i_if_numeric
      @red_alarm = data[:red_alarm].to_i_if_numeric
      @poller_uuid = data[:poller_uuid]
    end

    # Fill in interfaces
    if data == nil && (opts[:interfaces] || opts[:all])
      @interfaces = {}
      interfaces = API.get(
        src: 'device',
        dst: 'core',
        resource: "/v2/device/#{@name}/interfaces",
        what: "all interfaces on #{@name}",
      )
      interfaces.each do |index, int|
        next unless int.class == Interface
        @interfaces[int.index] = int
      end
    end

    # Fill in CPUs
    if data == nil && (opts[:cpus] || opts[:all])
      @cpus = {}
      cpus = API.get(
        src: 'device',
        dst: 'core',
        resource: "/v2/device/#{@name}/cpus",
        what: "all cpus on #{@name}",
      )
      cpus.each do |index, cpu|
        next unless cpu.class == CPU
        @cpus[cpu.index] = cpu
      end
    end

    # Fill in fans
    if data == nil && (opts[:fans] || opts[:all])
      @fans = {}
      fans = API.get(
        src: 'device',
        dst: 'core',
        resource: "/v2/device/#{@name}/fans",
        what: "all fans on #{@name}",
      )
      fans.each do |index, fan|
        next unless fan.class == Fan
        @fans[fan.index] = fan
      end
    end

    # Fill in memory
    if data == nil && (opts[:memory] || opts[:all])
      @memory = {}
      memories = API.get(
        src: 'device',
        dst: 'core',
        resource: "/v2/device/#{@name}/memory",
        what: "all memory on #{@name}",
      )
      memories.each do |index, memory|
        next unless memory.class == Memory
        @memory[memory.index] = memory
      end
    end

    # Fill in PSUs
    if data == nil && (opts[:psus] || opts[:all])
      @psus = {}
      psus = API.get(
        src: 'device',
        dst: 'core',
        resource: "/v2/device/#{@name}/psus",
        what: "all psus on #{@name}",
      )
      psus.each do |index, psu|
        next unless psu.class == PSU
        @psus[psu.index] = psu
      end
    end

    # Fill in temperatures
    if data == nil && (opts[:temperatures] || opts[:all])
      @temps = {}
      temps = API.get(
        src: 'device',
        dst: 'core',
        resource: "/v2/device/#{@name}/temperatures",
        what: "all temperatures on #{@name}",
      )
      temps.each do |index, temp|
        next unless temp.class == Temperature
        @temps[temp.index] = temp
      end
    end

    return self
  end


  def send
    start = Time.now.to_i
    if API.post(
      src: 'device',
      dst: 'core',
      resource: '/v2/device',
      what: "device #{@name}",
      data: to_json,
    )
      elapsed = Time.now.to_i - start
      $LOG.info("POLLER: POST successful for #{@name} (#{elapsed} seconds)")
      return true
    else
      $LOG.error("POLLER: POST failed for #{@name}; Aborting")
      return false
    end
  end


  def write_influxdb

    # Device series
    Influx.post(series: "#{@name}.bps_out", value: bps_out, time: @last_poll)
    Influx.post(series: "#{@name}.pps_out", value: pps_out, time: @last_poll)
    Influx.post(series: "#{@name}.discards_out", value: discards_out, time: @last_poll)
    Influx.post(series: "#{@name}.errors_out", value: errors_out, time: @last_poll)

    # Component series
    @interfaces.each { |index, interface| interface.write_influxdb }
    @cpus.each { |index, cpu| cpu.write_influxdb }
    @memory.each { |index, memory| memory.write_influxdb }
    @temps.each { |index, temp| temp.write_influxdb }

  end


  def save(db)

    # Remove keys from the from_json output that are not part of the device table
    not_keys = %w( interfaces memory temps cpus psus fans currently_polling )
    data = JSON.parse(self.to_json)['data'].delete_if { |k,v| not_keys.include?(k) }

    # Update the device table
    begin
      existing = db[:device].where(:device => @name)
      if existing.update(data) != 1
        db[:device].insert(data)
        $LOG.info("DEVICE: Created device #{@name}")
      end
    rescue Sequel::NotNullConstraintViolation => e
      $LOG.error("DEVICE: Save failed. Missing manditory values. #{e.to_s.gsub(/\n/,'. ')}")
      return nil
    end

    expire_time = Time.now.to_i - 300

    # If the interface was just updated, save it.  If not, delete it.
    @interfaces.each do |index, interface|
      interface.last_updated > expire_time ? interface.save(db) : interface.delete(db)
    end
    @cpus.each do |index, cpu|
      cpu.last_updated > expire_time ? cpu.save(db) : cpu.delete(db)
    end
    @fans.each do |index, fan|
      fan.last_updated > expire_time ? fan.save(db) : fan.delete(db)
    end
    @memory.each do |index, memory|
      memory.last_updated > expire_time ? memory.save(db) : memory.delete(db)
    end
    @psus.each do |index, psu|
      psu.last_updated > expire_time ? psu.save(db) : psu.delete(db)
    end
    @temps.each do |index, temp|
      temp.last_updated > expire_time ? temp.save(db) : temp.delete(db)
    end

    return self
  end


  def delete(db)
    int_count = 0
    cpu_count = 0
    fan_count = 0
    mem_count = 0
    psu_count = 0
    temp_count = 0

    @interfaces.values.each { |int| int_count += int.delete(db) }
    @cpus.values.each { |cpu| cpu_count += cpu.delete(db) }
    @fans.values.each { |fan| fan_count += fan.delete(db) }
    @memory.values.each { |mem| mem_count += mem.delete(db) }
    @psus.values.each { |psu| psu_count += psu.delete(db) }
    @temps.values.each { |temp| temp_count += temp.delete(db) }

    dev_count = db[:device].where(:device => @name).delete

    $LOG.info("DEVICE: Deleted device #{@name}") if dev_count == 1

    return dev_count + int_count + cpu_count + fan_count + mem_count + psu_count + temp_count
  end


  def to_json(*a)
    hash = {
      'json_class' => self.class.name,
      'data' => {
        'device' => @name,
      }
    }

    hash['data']['ip'] = @poll_ip if @poll_ip
    hash['data']['last_poll'] = @last_poll if @last_poll
    hash['data']['next_poll'] = @next_poll if @next_poll
    hash['data']['last_poll_duration'] = @last_poll_duration if @last_poll_duration
    hash['data']['last_poll_result'] = @last_poll_result if @last_poll_result
    hash['data']['last_poll_text'] = @last_poll_text if @last_poll_text
    hash['data']['currently_polling'] = @currently_polling if @currently_polling
    hash['data']['worker'] = @worker if @worker
    hash['data']['pps_out'] = pps_out
    hash['data']['bps_out'] = bps_out
    hash['data']['discards_out'] = discards_out
    hash['data']['errors_out'] = errors_out
    hash['data']['sys_descr'] = @sys_descr if @sys_descr
    hash['data']['vendor'] = @vendor if @vendor
    hash['data']['sw_descr'] = @sw_descr if @sw_descr
    hash['data']['sw_version'] = @sw_version if @sw_version
    hash['data']['hw_model'] = @hw_model if @hw_model
    hash['data']['uptime'] = @uptime if @uptime
    hash['data']['yellow_alarm'] = @yellow_alarm if @yellow_alarm
    hash['data']['red_alarm'] = @red_alarm if @red_alarm
    hash['data']['poller_uuid'] = @poller_uuid if @poller_uuid
    hash['data']['interfaces'] = @interfaces if @interfaces
    hash['data']['cpus'] = @cpus if @cpus
    hash['data']['fans'] = @fans if @fans
    hash['data']['memory'] = @memory if @memory
    hash['data']['psus'] = @psus if @psus
    hash['data']['temps'] = @temps if @temps

    hash.to_json(*a)
  end


  def self.json_create(json)
    data = json['data']
    Device.new(data['device']).populate(data)
  end


  private # All methods below are private!!


  # PRIVATE!
  def _poll_device_info(session)
    start = Time.now.to_i

    # SysDescr, for determining vendor
    session.get("1.3.6.1.2.1.1.1.0").each_varbind do |vb|
      @new_sys_descr = vb.value.to_s

      if @new_sys_descr =~ /Cisco/
        @new_vendor = 'Cisco'
      elsif @new_sys_descr =~ /Juniper|SRX/
        @new_vendor = 'Juniper'
      elsif @new_sys_descr =~ /Force10.*Series: S/m
        @new_vendor = 'Force10 S-Series'
      elsif @new_sys_descr =~ /Linux/
        @new_vendor = 'Linux'
      else
        # If we don't know what type of device this is:
        $LOG.warn("POLLER: Unknown device at #{ip}: #{@new_sys_descr}")
        @new_vendor = 'Unknown'
      end

      # Check for the existence of a regex for extracting sw/version info
      if sys_descr_regex = @poll_cfg[:sys_descr_regex][@new_vendor]
        if match = @new_sys_descr.match(sys_descr_regex)
          @new_sw_descr = match[1].strip
          @new_sw_version = match[2].strip
        end
      end

    end # /session.get

    # Get HW info (model)
    session.get('1.3.6.1.2.1.1.2.0').each_varbind do |vb|
      @new_hw_model = (vb.value.to_s.split('::')[1] || '').gsub('jnxProductName','')
    end

    # Get alarms
    vendor_oids = @poll_cfg[:oids][@new_vendor] || {}
    if vendor_oids['yellow_alarm']
      session.get(vendor_oids['yellow_alarm']).each_varbind { |vb| @new_yellow_alarm = vb.value.to_i }
    end
    if vendor_oids['red_alarm']
      session.get(vendor_oids['red_alarm']).each_varbind { |vb| @new_red_alarm = vb.value.to_i }
    end

    # Get uptime
    session.get('1.3.6.1.2.1.1.3.0').each_varbind { |vb| @new_uptime = vb.value.to_i / 100 }

    # Update values
    #   This could be its own method if we want to extend functionality later
    #   ie. send alerts on significant changes (alarm status, uptime reset, etc)
    @sys_descr = @new_sys_descr
    @vendor = @new_vendor
    @sw_descr = @new_sw_descr
    @sw_version = @new_sw_version
    @hw_model = @new_hw_model
    @uptime = @new_uptime
    @yellow_alarm = @new_yellow_alarm
    @red_alarm = @new_red_alarm
    @last_poll = Time.now.to_i
    @next_poll = Time.now.to_i + 100

    return Time.now.to_i - start
  end


  # PRIVATE!
  def _poll_interfaces(session)
    start = Time.now.to_i

    if_table = {}

    session.walk(@poll_cfg[:oids][:general].keys) do |row|
      row.each do |vb|
        oid_text = @poll_cfg[:oids][:general][vb.name.to_str.gsub(/\.[0-9]+$/,'')]
        index = vb.name.to_str[/[0-9]+$/].to_i
        if_table[index] ||= {}
        if_table[index][oid_text] = vb.value.to_s
      end
    end

    if_table.each do |index, oids|
      # Don't create the interface unless it has an interesting alias or an interesting name
      next unless (
        oids['alias'] =~ @poll_cfg[:interesting_alias] ||
        oids['name'] =~ @poll_cfg[:interesting_names][@vendor]
      )
      # Don't create the interface if we weren't able to poll the octet information
      next unless oids['hc_in_octets'].to_s =~ /[0-9]+/

      @interfaces[index] ||= Interface.new(device: @name, index: index)
      @interfaces[index].update(oids, worker: @worker) if oids && !oids.empty?
    end

    return Time.now.to_i - start
  end


  # PRIVATE!
  def _poll_cpus(session)
    start = Time.now.to_i

    # Delete all the irrelevant vendor_cfg values (to prevent .invert from having duplicates)
    return nil unless vendor_cfg = @poll_cfg[:oids][@vendor].dup.delete_if { |k,v| k !~ /^cpu_/ }
    return nil unless vendor_cfg['cpu_util']

    # Some of these may not exist (vendor dependant). Nils will be removed with compact! below.
    cpu_oids = [
      vendor_cfg['cpu_util'],
      vendor_cfg['cpu_hw_id'],
      vendor_cfg['cpu_description'],
    ]
    cpu_oids.compact! # Removes nil values from Array

    cpu_table = {}

    session.walk(cpu_oids) do |row|
      row.each do |vb|
        # Save the base OID (without index component), then use that to look up the
        #   OID text for the OID being processed
        oid_without_index = vb.name.to_str.gsub(vendor_cfg['cpu_index_regex'],'').gsub(/\.$/,'')
        oid_text = vendor_cfg.invert[oid_without_index].gsub('cpu_','')

        index = vendor_cfg['cpu_index_regex'].match( vb.name.to_str )[0]
        cpu_table[index] ||= {}
        cpu_table[index][oid_text] = vb.value.to_s
      end
    end

    # Get descriptions for CPUs with hardware IDs (Cisco style)
    if hw_descr_oid = vendor_cfg['cpu_hw_description']
      cpu_table.each do |index, oids|
        session.get("#{hw_descr_oid}.#{oids['hw_id']}").each_varbind do |vb|
          # Skip missing descriptions
          next if vb.value == SNMP::NoSuchInstance
          cpu_table[index]['description'] ||= vb.value.to_s
        end
      end
    end

    # Update cpu values
    cpu_table.each do |index, oids|
      # Skip CPUs we don't care about (next if cpu_list_regex
      #   exists and doesn't match the index.
      next if vendor_cfg['cpu_list_regex'] && !(vendor_cfg['cpu_list_regex'] =~ index)

      @cpus[index] ||= CPU.new(device: @name, index: index)
      @cpus[index].update(oids, worker: @worker) if oids && !oids.empty?
    end

    return Time.now.to_i - start
  end


  # PRIVATE!
  def _poll_fans(session)
    start = Time.now.to_i

    # Delete all the irrelevant vendor_cfg values (to prevent .invert from having duplicates)
    return nil unless vendor_cfg = @poll_cfg[:oids][@vendor].dup.delete_if { |k,v| k !~ /^fan_/ }
    return nil unless vendor_cfg['fan_vendor_status']

    # Some of these may not exist (vendor dependant). Nils will be removed with compact! below.
    fan_oids = [
      vendor_cfg['fan_description'],
      vendor_cfg['fan_vendor_status'],
    ]
    fan_oids.compact! # Removes nil values from Array

    fan_table = {}

    session.walk(fan_oids) do |row|
      row.each do |vb|
        # Save the base OID (without index component), then use that to look up the
        #   OID text for the OID being processed
        oid_without_index = vb.name.to_str.gsub(vendor_cfg['fan_index_regex'],'').gsub(/\.$/,'')
        oid_text = vendor_cfg.invert[oid_without_index].gsub('fan_','')

        index = vendor_cfg['fan_index_regex'].match( vb.name.to_str )[0]
        fan_table[index] ||= {}
        fan_table[index][oid_text] = vb.value.to_s
      end
    end

    # Normalize status from vendor status --> Pixel status
    fan_table.each do |index, oids|
      status, status_text = _normalize_status(oids['vendor_status'])
      fan_table[index]['status'] = status
      fan_table[index]['status_text'] = status_text
    end

    # Update fan values
    fan_table.each do |index, oids|
      @fans[index] ||= Fan.new(device: @name, index: index)
      @fans[index].update(oids, worker: @worker) if oids && !oids.empty?
    end

    return Time.now.to_i - start
  end


  # PRIVATE!
  def _poll_memory(session)
    start = Time.now.to_i

    # Delete all the irrelevant vendor_cfg values (to prevent .invert from having duplicates)
    return nil unless vendor_cfg = @poll_cfg[:oids][@vendor].dup.delete_if { |k,v| k !~ /^mem_/ }
    return nil unless vendor_cfg['mem_util'] || vendor_cfg['mem_free']

    # Some of these may not exist (vendor dependant). Nils will be removed with compact! below.
    mem_oids = [
      vendor_cfg['mem_total'],
      vendor_cfg['mem_used'],
      vendor_cfg['mem_free'],
      vendor_cfg['mem_description'],
      vendor_cfg['mem_util'],
    ]
    mem_oids.compact! # Removes nil values from Array

    mem_table = {}

    session.walk(mem_oids) do |row|
      row.each do |vb|
        # Save the base OID (without index component), then use that to look up the
        #   OID text for the OID being processed
        oid_without_index = vb.name.to_str.gsub(vendor_cfg['mem_index_regex'],'').gsub(/\.$/,'')
        oid_text = vendor_cfg.invert[oid_without_index].gsub('mem_','')

        index = vendor_cfg['mem_index_regex'].match( vb.name.to_str )[0]
        mem_table[index] ||= {}
        mem_table[index][oid_text] = vb.value.to_s
      end
    end

    # If we didn't get the utilization directly, calculate it
    if vendor_cfg['mem_util'] == nil
      mem_table.each do |index, oids|
        mem_free = oids['free'].to_i # Always present
        mem_used = oids['used'].to_i_if_numeric # Will be nil unless Cisco style
        mem_total = oids['total'].to_i_if_numeric # Will be nil unless Linux style

        oids['util'] = (mem_used.to_f / (mem_used + mem_free) * 100).to_i if mem_used
        oids['util'] = ((mem_total - mem_free).to_f / mem_total * 100).to_i if mem_total
      end
    end

    # Update mem values
    mem_table.each do |index, oids|
      # Skip Memory we don't care about (next if mem_list_regex
      #   exists and doesn't match the index.
      next if vendor_cfg['mem_list_regex'] && !(vendor_cfg['mem_list_regex'] =~ index)

      @memory[index] ||= Memory.new(device: @name, index: index)
      @memory[index].update(oids, worker: @worker) if oids && !oids.empty?
    end

    return Time.now.to_i - start
  end


  # PRIVATE!
  def _poll_psus(session)
    start = Time.now.to_i

    # Delete all the irrelevant vendor_cfg values (to prevent .invert from having duplicates)
    return nil unless vendor_cfg = @poll_cfg[:oids][@vendor].dup.delete_if { |k,v| k !~ /^psu_/ }
    return nil unless vendor_cfg['psu_vendor_status']

    # Some of these may not exist (vendor dependant). Nils will be removed with compact! below.
    psu_oids = [
      vendor_cfg['psu_description'],
      vendor_cfg['psu_vendor_status'],
    ]
    psu_oids.compact! # Removes nil values from Array

    psu_table = {}

    session.walk(psu_oids) do |row|
      row.each do |vb|
        # Save the base OID (without index component), then use that to look up the
        #   OID text for the OID being processed
        oid_without_index = vb.name.to_str.gsub(vendor_cfg['psu_index_regex'],'').gsub(/\.$/,'')
        oid_text = vendor_cfg.invert[oid_without_index].gsub('psu_','')

        index = vendor_cfg['psu_index_regex'].match( vb.name.to_str )[0]
        psu_table[index] ||= {}
        psu_table[index][oid_text] = vb.value.to_s
      end
    end

    # Normalize status from vendor status --> Pixel status
    psu_table.each do |index, oids|
      status, status_text = _normalize_status(oids['vendor_status'])
      psu_table[index]['status'] = status
      psu_table[index]['status_text'] = status_text
    end

    # Update psu values
    psu_table.each do |index, oids|
      @psus[index] ||= PSU.new(device: @name, index: index)
      @psus[index].update(oids, worker: @worker) if oids && !oids.empty?
    end

    return Time.now.to_i - start
  end


  # PRIVATE!
  def _poll_temperatures(session)
    start = Time.now.to_i

    # Delete all the irrelevant vendor_cfg values (to prevent .invert from having duplicates)
    return nil unless vendor_cfg = @poll_cfg[:oids][@vendor].dup.delete_if { |k,v| k !~ /^temp_/ }
    return nil unless vendor_cfg['temp_temperature']

    # Some of these may not exist (vendor dependant). Nils will be removed with compact! below.
    temperature_oids = [
      vendor_cfg['temp_description'],
      vendor_cfg['temp_threshold'],
      vendor_cfg['temp_vendor_status'],
      vendor_cfg['temp_temperature'],
    ]
    temperature_oids.compact! # Removes nil values from Array

    temp_table = {}

    session.walk(temperature_oids) do |row|
      row.each do |vb|
        # Save the base OID (without index component), then use that to look up the
        #   OID text for the OID being processed
        oid_without_index = vb.name.to_str.gsub(vendor_cfg['temp_index_regex'],'').gsub(/\.$/,'')
        oid_text = vendor_cfg.invert[oid_without_index].gsub('temp_','')

        index = vendor_cfg['temp_index_regex'].match( vb.name.to_str )[0]
        temp_table[index] ||= {}
        temp_table[index][oid_text] = vb.value.to_s
      end
    end

    # Remove any 0 value temperatures, these typically mean no sensor present
    temp_table.delete_if { |index, oids| oids['temperature'].to_i == 0 }

    # Normalize status from vendor status --> Pixel status
    temp_table.each do |index, oids|
      status, status_text = _normalize_status(oids['vendor_status'])
      temp_table[index]['status'] = status
      temp_table[index]['status_text'] = status_text
    end

    # Update temperature values
    temp_table.each do |index, oids|
      @temps[index] ||= Temperature.new(device: @name, index: index)
      @temps[index].update(oids, worker: @worker) if oids && !oids.empty?
    end

    return Time.now.to_i - start
  end


  # PRIVATE!
  def _process_interfaces
    start = Time.now.to_i

    # If the vendor is Force10, replace interface names:
    if @vendor == 'Force10 S-Series'
      substitutions = {
        'Port-channel ' => 'Po',
        'fortyGigE ' => 'Fo',
        'TenGigabitEthernet ' => 'Te',
        'GigabitEthernet ' => 'Gi',
        'FastEthernet ' => 'Fa',
        'ManagementEthernet ' => 'Ma',
      }
      @interfaces.each { |index, int| int.substitute_name(substitutions) }
    end

    # Loop through all interfaces
    @interfaces.each do |index, interface|

      # TODO: REPLACE THIS WITH SSH!! This is retarded!
      # If an interface is up w/ a speed of 0, try to get speed from children
      if interface.status == 'Up' && interface.speed == 0
        child_count = 0
        child_speed = 0
        @interfaces.each do |tmp_index, tmp_interface|
          # Add one to the count and set the child speed for each interface we find
          # containing [xx], where xx is the parent interface name
          if tmp_interface.alias.match(/\[#{interface.name}\]/) && tmp_interface.status == 'Up'
            child_count += 1
            child_speed = tmp_interface.speed
          end
        end
        interface.set_speed(child_count * child_speed)
        $LOG.warn("POLLER: Bad speed for #{interface.name} (#{index}) on #{@name}. Calculated value from children: #{interface.speed}")
      end

      # TODO: REPLACE THIS WITH SSH!!! This is ALSO retarded!
      # Find the parent interface if it exists, and transfer its type to child.
      if parent_iface_match = interface.alias.match(/^[a-z]+\[([\w\/\-\s]+)\]/)
        parent_iface = parent_iface_match[1]
        if parent = get_interface(name: parent_iface)
          interface.clone_type(parent)
        else
          $LOG.error("POLLER: Can't find parent interface #{parent_iface} on #{@name} (child: #{interface.name})")
        end
      end

    end

    return Time.now.to_i - start
  end


  # PRIVATE!
  def _normalize_status(vendor_status)
    table = @poll_cfg[:status_table]
    vendor_status = vendor_status.to_i

    # If a vendor status table exists, get the status from there.
    #   If the vendor status table doesn't exist, or the vendor status
    #   isn't listed there, set status to 0 ("Unknown")
    status = table[@vendor] ? (table[@vendor][vendor_status] || 0) : 0
    status_text = table['Pixel'][status]

    return status, status_text
  end


  # PRIVATE!
  def _open_poll_session
    SNMP::Manager.new(
      :host => @poll_ip,
      :community => @poll_cfg[:snmpv2_community],
      :mib_dir => 'lib/mibs',
      :mib_modules => [
        'CISCO-PRODUCTS-MIB',
        'JNX-CHAS-DEFINES-MIB',
        'F10-PRODUCTS-MIB',
      ])
  end


end
