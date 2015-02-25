# device.rb
require_relative 'interface'

class Device


  def initialize(name, poll_ip: nil, poll_cfg: nil)

    # required
    @name = name

    # optional
    @poll_ip = poll_ip
    @poll_cfg = poll_cfg

    @interfaces = {}
    @cpus = {}
    @memory = {}
    @temperatures = {}
    @psus = {}
    @fans = {}
    @macs = []

  end

  
  # Return an array containing all Interface objects in the device
  def interfaces
    @interfaces.values
  end


  def poll(worker:, poll_ip: nil, poll_cfg: nil)
    @new_worker = worker

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

      _poll_device_info(session)
      _poll_interfaces(session)
      _process_interfaces

    rescue RuntimeError, ArgumentError => e
      $LOG.error("POLLER: Error encountered while polling #{device}: #{e}")
    ensure
      session.close if session
    end

    return self
  end


  def save
  end


  def populate(opts=[])

    # First get device metadata from pixel API & update instance variables
    metadata = API.get('core', "/v1/device/#{@name}", 'Device', 'device data')

    # Return if the device wasn't found
    return nil unless metadata['device']

    # Update instance variables
    @poll_ip = metadata['ip']
    @last_poll = metadata['last_poll'].to_i_if_numeric
    @next_poll = metadata['next_poll'].to_i_if_numeric
    @last_poll_duration = metadata['last_poll_duration'].to_i_if_numeric
    @last_poll_result = metadata['last_poll_result'].to_i_if_numeric
    @last_poll_text = metadata['last_poll_text']
    @currently_polling = metadata['currently_polling'].to_i_if_numeric
    @worker = metadata['worker']
    @pps_out = metadata['pps_out'].to_i_if_numeric
    @bps_out = metadata['bps_out'].to_i_if_numeric
    @discards_out = metadata['discards_out'].to_i_if_numeric
    @sys_descr = metadata['sys_descr']
    @vendor = metadata['vendor']
    @sw_descr = metadata['sw_descr']
    @sw_version = metadata['sw_version']
    @hw_model = metadata['hw_model']
    @uptime = metadata['uptime'].to_i_if_numeric
    @yellow_alarm = metadata['yellow_alarm'].to_i_if_numeric
    @red_alarm = metadata['red_alarm'].to_i_if_numeric

    # Fill in interfaces
    @interfaces = {}
    if opts.include?(:interfaces)
      interfaces = API.get('core', "/v1/device/#{@name}/interfaces", 'Device', 'interface data')
      interfaces.each do |interface_data|
        index = interface_data['index']
        @interfaces[index] = Interface.new(device: @name, index: index)
        @interfaces[index].populate(interface_data)
      end
    end

    @cpus = {}
    if opts.include?(:cpus)
      cpus = API.get('core', "/v1/devices/#{@name}/cpus", 'Device', 'cpu data')
    end

    @memory = {}
    if opts.include?(:memory)
      memory = API.get('core', "/v1/devices/#{@name}/memory", 'Device', 'memory data')
    end

    @temperatures = {}
    if opts.include?(:temperatures)
      temperatures = API.get('core', "/v1/devices/#{@name}/temperatures", 'Device', 'temperature data')
    end

    @psus = {}
    if opts.include?(:psus)
      psus = API.get('core', "/v1/devices/#{@name}/psus", 'Device', 'psu data')
    end

    @fans = {}
    if opts.include?(:fans)
      fans = API.get('core', "/v1/devices/#{@name}/fans", 'Device', 'fan data')
    end

    @macs = {}
    if opts.include?(:macs)
      macs = API.get('core', "/v1/devices/#{@name}/macs", 'Device', 'mac data')
    end

    return self

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

  end


  # PRIVATE!
  def _poll_interfaces(session)
    if_table = {}

    session.walk(@poll_cfg[:oids][:general].keys) do |row|
      row.each do |vb|
        oid_text = @poll_cfg[:oids][:general][vb.name.to_str.gsub(/\.[0-9]+$/,'')]
        if_index = vb.name.to_str[/[0-9]+$/]
        if_table[if_index] ||= {}
        if_table[if_index][oid_text] = vb.value.to_s
        # The following line removes ' characters from the beginning
        #   and end of aliases (Linux does this)
        #if_table[if_index][oid_text].gsub!(/^'|'$/,'') if oid_text == 'if_alias'
      end
    end

    if_table.each do |index, oids|
      # Don't create the interface unless it has an interesting alias or an interesting name
      next unless (
        oids['if_alias'] =~ @poll_cfg[:interesting_alias] ||
        oids['if_name'] =~ @poll_cfg[:interesting_names[@vendor]]
      )
      @interfaces ||= []
      @interfaces[index] ||= Interface.new(device: @device, index: index)
      @interfaces[index].update(oids) if oids && !oids.empty?
    end
  end


  def _process_interfaces
    # Loop through all interfaces
    @interfaces.each do |index, interface|

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
        interfaces.each do |index, interface|
          interface.substitute_name(substitutions)
        end
      end

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
    end

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
