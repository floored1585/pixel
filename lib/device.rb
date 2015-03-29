# device.rb
require 'logger'
require 'snmp'
require_relative 'api'
require_relative 'configfile'
require_relative 'core_ext/object'
require_relative 'interface'
require_relative 'temperature'
require_relative 'memory'
require_relative 'fan'
require_relative 'psu'
require_relative 'cpu'

$LOG ||= Logger.new('device.log')

class Device


  def initialize(name, poll_ip: nil, poll_cfg: nil)

    # required
    @name = name

    # optional
    @poll_ip = poll_ip
    @poll_cfg = poll_cfg || Configfile.retrieve['poller']

    @interfaces = {}
    @memory = {}
    @temps = {}
    @cpus = {}
    @psus = {}
    @fans = {}

  end

  
  # Return an array containing all Interface objects in the device
  def interfaces
    @interfaces.values
  end


  # Return an array containing all Temperature objects in the device
  def temps
    @temps.values
  end


  # Return an array containing all Fan objects in the device
  def fans
    @fans.values
  end


  # Return an array containing all PSU objects in the device
  def psus
    @psus.values
  end


  # Return an array containing all CPU objects in the device
  def cpus
    @cpus.values
  end


  # Return an array containing all Memory objects in the device
  def memory
    @memory.values
  end


  def name
    @name
  end
  def worker
    @worker
  end


  def get_interface(name: nil, index: nil)
    # Return nil unless either a name or index was passed
    return nil unless name || index

    return @interfaces[index.to_i_if_numeric] if index
    @interfaces.each { |index, int| return int if name.downcase == int.name.downcase }

    return nil # If nothing matched
  end


  def poll(worker:, poll_ip: nil, poll_cfg: nil)
    @worker = worker

    # If poll_ip or poll_cfg were passed in, update them
    @poll_ip = poll_ip if poll_ip
    @poll_cfg = poll_cfg if poll_cfg

    # Return if we don't have everything needed to poll
    unless @poll_cfg && @poll_ip
      $LOG.error("Device<#{@name}>: Can't execute poll with no poll_cfg or poll_ip")
      return nil
    end

    # Exception handling for SNMP errors
    begin
      session = _open_poll_session

      # Poll the device
      _poll_device_info(session)
      _poll_interfaces(session)
      _poll_temperatures(session)
      _poll_memory(session)
      _poll_cpus(session)
      _poll_psus(session)
      _poll_fans(session)

      # Post-processing
      _process_interfaces

    rescue RuntimeError, ArgumentError => e
      $LOG.error("POLLER: Error encountered while polling #{@name}: #{e}")
      # TODO: Write the failure to db & reset currently_polling
    ensure
      session.close if session
    end

    return self
  end


  def populate(opts={})

    # Read any data passed into populate, and if it's present do not
    # get data from the API later (if JSON data is passed, ONLY use that)
    data = opts['data']
    data = JSON.load(data.to_json) if data # To allow for raw JSON and already-loaded JSON
    get_data = true if data == nil

    # First get device metadata from pixel API & update instance variables
    data ||= API.get('core', "/v2/device/#{@name}", 'Device', 'device data')

    # These will all be nil unless data was passed into populate via opts
    @interfaces = data['interfaces'] || {}
    # Convert keys to integers for @interface
    @interfaces = Hash[@interfaces.map{|key,int|[ key.to_i, int ]}]
    @memory = data['memory'] || {}
    @temps = data['temps'] || {}
    @cpus = data['cpus'] || {}
    @psus = data['psus'] || {}
    @fans = data['fans'] || {}

    # Return if the device wasn't found
    return nil unless data['device']

    # Update instance variables
    @poll_ip = data['ip']
    @last_poll = data['last_poll'].to_i_if_numeric
    @next_poll = data['next_poll'].to_i_if_numeric
    @last_poll_duration = data['last_poll_duration'].to_i_if_numeric
    @last_poll_result = data['last_poll_result'].to_i_if_numeric
    @last_poll_text = data['last_poll_text']
    @currently_polling = data['currently_polling'].to_i_if_numeric
    @worker = data['worker']
    @pps_out = data['pps_out'].to_i_if_numeric
    @bps_out = data['bps_out'].to_i_if_numeric
    @discards_out = data['discards_out'].to_i_if_numeric
    @sys_descr = data['sys_descr']
    @vendor = data['vendor']
    @sw_descr = data['sw_descr']
    @sw_version = data['sw_version']
    @hw_model = data['hw_model']
    @uptime = data['uptime'].to_i_if_numeric
    @yellow_alarm = data['yellow_alarm'].to_i_if_numeric
    @red_alarm = data['red_alarm'].to_i_if_numeric

    # Fill in interfaces
    if get_data && (opts[:interfaces] || opts[:all])
      @interfaces = {}
      interfaces = API.get('core', "/v2/device/#{@name}/interfaces", 'Device', 'interface data') 
      interfaces.each do |interface_data|
        # eliminate the 'data' key when building object from json
        interface_data = interface_data.delete('data') || interface_data
        index = interface_data['index']
        @interfaces[index] = Interface.new(device: @name, index: index).populate(interface_data)
      end
    end

    # Fill in CPUs
    if get_data && (opts[:cpus] || opts[:all])
      @cpus = {}
      cpus = API.get('core', "/v2/device/#{@name}/cpus", 'Device', 'cpu data')
      cpus.each do |cpu_data|
        # eliminate the 'data' key when building object from json
        cpu_data = cpu_data.delete('data') || cpu_data
        index = cpu_data['index']
        @cpus[index] = CPU.new(device: @name, index: index).populate(cpu_data)
      end
    end

    # Fill in memory
    if get_data && (opts[:memory] || opts[:all])
      @memory = {}
      memory = API.get('core', "/v2/device/#{@name}/memory", 'Device', 'memory data')
      memory.each do |memory_data|
        # eliminate the 'data' key when building object from json
        memory_data = memory_data.delete('data') || memory_data
        index = memory_data['index']
        @memory[index] = Memory.new(device: @name, index: index).populate(memory_data)
      end
    end

    # Fill in temperatures
    if get_data && (opts[:temperatures] || opts[:all])
      @temps = {}
      temps = API.get('core', "/v2/device/#{@name}/temperatures", 'Device', 'temperature data')
      temps.each do |temperature_data|
        # eliminate the 'data' key when building object from json
        temperature_data = temperature_data.delete('data') || temperature_data
        index = temperature_data['index']
        @temps[index] = Temperature.new(device: @name, index: index).populate(temperature_data)
      end
    end

    # Fill in PSUs
    if get_data && (opts[:psus] || opts[:all])
      @psus = {}
      psus = API.get('core', "/v2/device/#{@name}/psus", 'Device', 'psu data')
      psus.each do |psu_data|
        # eliminate the 'data' key when building object from json
        psu_data = psu_data.delete('data') || psu_data
        index = psu_data['index']
        @psus[index] = PSU.new(device: @name, index: index).populate(psu_data)
      end
    end

    # Fill in fans
    if get_data && (opts[:fans] || opts[:all])
      @fans = {}
      fans = API.get('core', "/v2/device/#{@name}/fans", 'Device', 'fan data')
      fans.each do |fan_data|
        # eliminate the 'data' key when building object from json
        fan_data = fan_data.delete('data') || fan_data
        index = fan_data['index']
        @fans[index] = Fan.new(device: @name, index: index).populate(fan_data)
      end
    end

    return self

  end


  def send
    start = Time.now.to_i
    if API.post('core', '/v2/device', to_json, 'POLLER', 'poll results')
      elapsed = Time.now.to_i - start
      $LOG.info("POLLER: POST successful for #{devices.keys[0]} (#{elapsed} seconds)")
    else
      $LOG.error("POLLER: POST failed for #{devices.keys[0]} (#{elapsed} seconds); Aborting")
    end
  end


  def save
  end


  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data' => {
        'device' => @name,
        'ip' => @poll_ip,
        'last_poll' => @last_poll,
        'next_poll' => @next_poll,
        'last_poll_duration' => @last_poll_duration,
        'last_poll_result' => @last_poll_result,
        'last_poll_text' => @last_poll_text,
        'currently_polling' => @currently_polling,
        'worker' => @worker,
        'pps_out' => @pps_out,
        'bps_out' => @bps_out,
        'discards_out' => @discards_out,
        'sys_descr' => @sys_descr,
        'vendor' => @vendor,
        'sw_descr' => @sw_descr,
        'sw_version' => @sw_version,
        'hw_model' => @hw_model,
        'uptime' => @uptime,
        'yellow_alarm' => @yellow_alarm,
        'red_alarm' => @red_alarm,
        'interfaces' => @interfaces,
        'memory' => @memory,
        'temps' => @temps,
        'cpus' => @cpus,
        'psus' => @psus,
        'fans' => @fans,
      }
    }.to_json(*a)

  end


  def self.json_create(json)
    data = json['data']
    Device.new(data['device']).populate(:all => true, 'data' => data)
  end


  private # All methods below are private!!


  # PRIVATE!
  def _poll_device_info(session)

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
      session.get(vendor_oids['yellow_alarm']).each_varbind { |vb| @new_yellow_alarm = vb.value }
    end
    if vendor_oids['red_alarm']
      session.get(vendor_oids['red_alarm']).each_varbind { |vb| @new_red_alarm = vb.value }
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

  end


  # PRIVATE!
  def _poll_interfaces(session)
    if_table = {}

    session.walk(@poll_cfg[:oids][:general].keys) do |row|
      row.each do |vb|
        oid_text = @poll_cfg[:oids][:general][vb.name.to_str.gsub(/\.[0-9]+$/,'')]
        if_numericndex = vb.name.to_str[/[0-9]+$/].to_i
        if_table[if_numericndex] ||= {}
        if_table[if_numericndex][oid_text] = vb.value.to_s
        # The following line removes ' characters from the beginning
        #   and end of aliases (Linux does this)
        #if_table[if_numericndex][oid_text].gsub!(/^'|'$/,'') if oid_text == 'if_alias'
      end
    end

    if_table.each do |index, oids|
      # Don't create the interface unless it has an interesting alias or an interesting name
      next unless (
        oids['if_alias'] =~ @poll_cfg[:interesting_alias] ||
        oids['if_name'] =~ @poll_cfg[:interesting_names[@vendor]]
      )
      @interfaces[index] ||= Interface.new(device: @name, index: index)
      @interfaces[index].update(oids) if oids && !oids.empty?
    end

  end


  # PRIVATE!
  def _poll_temperatures(session)
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
      @temps[index].update(oids) if oids && !oids.empty?
    end

  end


  # PRIVATE!
  def _poll_memory(session)
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
      @memory[index].update(oids) if oids && !oids.empty?
    end

  end


  # PRIVATE!
  def _poll_cpus(session)
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
      @cpus[index].update(oids) if oids && !oids.empty?
    end

  end


  # PRIVATE!
  def _poll_psus(session)
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
      @psus[index].update(oids) if oids && !oids.empty?
    end

  end


  # PRIVATE!
  def _poll_fans(session)
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
      @fans[index].update(oids) if oids && !oids.empty?
    end

  end


  # PRIVATE!
  def _process_interfaces

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
        $LOG.warn("POLLER: Bad speed for #{interface.name} (#{index}) on #{@name}. Calculated value from children: #{@speed}")
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


  def write_to_influxdb
    @interfaces.each { |index, interface| interface.write_to_influxdb }
    #TODO
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
