require 'socket'
require 'influxdb'
require 'snmp'
require 'net/http'
require 'json'
require 'uri'
require_relative 'core_ext/hash'

module Poller


  def self.check_for_work(settings, db)
    poller_cfg = _poller_cfg(settings)
    concurrency = poller_cfg[:concurrency]
    request = "/v1/devices/fetch_poll?count=#{concurrency}&hostname=#{Socket.gethostname}"

    if devices = API.get('core', request, 'POLLER', 'devices to poll', 0)
      devices.each { |device, ip| _poll(poller_cfg, device, ip) }
      return 200 # Doesn't do any error checking here
    else # HTTP request failed
      return 500
    end
  end


  def self._poll(poll_cfg, device_name, ip)
    pid = fork do
      start_time = Time.now
      metadata = { :worker => Socket.gethostname }

      # get SNMP data from the device
      start = Time.now
      start_total = Time.now

      device = Device.new(device_name, poll_ip: ip, poll_cfg: poll_cfg)

      # Get current values for interfaces
      device.populate([:interfaces])

      # Poll for new values
      if device.poll(poller_cfg, worker: Socket.gethostname)

        # Calculate / process polled values
        device.update

        # Send the data back to Pixel core
        device.save
      else
        $LOG.error("POLLER: Poll failed for #{device_name}")
      end






      begin
        dev_info = _query_device_info(ip, poller_cfg)
        dev_info_time = Time.now - start; start = Time.now

        cpus = _query_device_cpu(device, ip, poller_cfg, dev_info[:vendor])
        cpus_time = Time.now - start; start = Time.now

        memory = _query_device_mem(device, ip, poller_cfg, dev_info[:vendor])
        memory_time = Time.now - start; start = Time.now

        temperature = _query_device_temp(device, ip, poller_cfg, dev_info[:vendor])
        temperature_time = Time.now - start; start = Time.now

        psu = _query_device_psu(device, ip, poller_cfg, dev_info[:vendor])
        psu_time = Time.now - start; start = Time.now

        fan = _query_device_fan(device, ip, poller_cfg, dev_info[:vendor])
        fan_time = Time.now - start; start = Time.now

        if_table = _query_device_interfaces(ip, poller_cfg)
        if_table_time = Time.now - start; start = Time.now

        total_time = Time.now - start_total

        #puts "#{device} Fan Data:"
        #pp if_table if device.include?('cr-1') || device == 'iad1-d-1' || device == 'gar-p1u1-dist'
        #puts "\n"
      rescue RuntimeError, ArgumentError => e
        $LOG.error("POLLER: Error encountered while polling #{device}: #{e}")
        metadata[:last_poll_result] = 1
        post_devices = { device => {
          :metadata => metadata,
          :interfaces => {},
          :cpus => {},
          :memory => {},
          :temperature => {},
          :psu => {},
          :fan => {},
          :devicedata => {},
        } }
        _post_data(post_devices)
      end
      #$LOG.info(
      #  "POLLER: SNMP poll successful:\n" +
      #  "Dev: #{device}\n" +
      #  "dev_info_time: #{'%.2f' % dev_info_time}\n" +
      #  "cpus_time: #{'%.2f' % cpus_time}\n" +
      #  "memory_time: #{'%.2f' % memory_time}\n" +
      #  "temperature_time: #{'%.2f' % temperature_time}\n" +
      #  "psu_time: #{'%.2f' % psu_time}\n" +
      #  "fan_time: #{'%.2f' % fan_time}\n" +
      #  "if_table_time: #{'%.2f' % if_table_time}\n" +
      #  "Total Time: #{'%.2f' % total_time}"
      #)


      total_polled = if_table.size

      # Populate name_to_index hash
      name_to_index = {}
      if_table.each { |index,oids| name_to_index[oids['if_name'].downcase] = index }

      influx_is_up = true

      cpus.each do |index, data|
        series_name = "#{device}.cpu.#{data[:description]}"
        series_data = { :value => data[:util], :time => Time.now.to_i }
        influx_is_up = _write_influxdb(series_name, series_data, poller_cfg) if influx_is_up
      end
      memory.each do |index, data|
        series_name = "#{device}.memory.#{data[:description]}"
        series_data = { :value => data[:util], :time => Time.now.to_i }
        influx_is_up = _write_influxdb(series_name, series_data, poller_cfg) if influx_is_up
      end

      # TODO: Need to use stale_indexes to delete stuff
      stale_indexes, last_values = _get_last_values(device, if_table)
      _delete_interfaces(stale_indexes) if stale_indexes[device][:interface].length > 0

      # Run through the hash we got from poll, processing the interesting interfaces
      interfaces = {}
      totals = { 'pps_out' => 0, 'bps_out' => 0, 'discards_out' => 0 }
      if_table.each do |if_index, oids|
        # Call _process_interface to do the heavy lifting
        interfaces[if_index] = _process_interface(device, if_table.dup, if_index, oids, last_values, poller_cfg, influx_is_up)
        # Update totals
        totals.keys.each { |key| totals[key] += interfaces[if_index][key] || 0 unless oids['if_name'].downcase =~ /ae|po|bond/  }
        # Find the parent interface if it exists, and transfer its type to child.
        # Otherwise (if we're not a child) look at our own type.
        # I hate this logic, but can't think of a better way to do it.
        parent_iface_match = oids['if_alias'].match(/^[a-z]+\[([\w\/\-\s]+)\]/) || []
        if parent_iface = parent_iface_match[1]
          if parent_index = name_to_index[parent_iface.downcase]
            parent_alias = if_table[parent_index]['if_alias']
            if parent_alias_match = parent_alias.match(/^([a-z]+)(__|\[)/)
              oids[:if_type] = parent_alias_match[1]
            else
              $LOG.error("POLLER: Can't determine parent if_type: #{oids['if_name']} on #{device}")
            end
          else
            $LOG.error("POLLER: Can't find parent interface #{parent_iface} on device #{device} (child: #{oids['if_name']})")
            oids[:if_type] = 'unknown'
          end
        else
          if match = oids['if_alias'].match(/^([a-z]+)(__|\[)/)
            oids[:if_type] = match[1]
          else
            oids[:if_type] = 'unknown'
          end
        end
      end

      # Push the totals to influx
      totals.keys.each do |key|
        metadata[key.to_sym] = totals[key] # for application
        series_name = "#{device}.#{key}"
        series_data = { :value => totals[key], :time => Time.now.to_i }
        influx_is_up = _write_influxdb(series_name, series_data, poller_cfg) if influx_is_up
      end
      elapsed = Time.now.to_i - start.to_i
      $LOG.info("POLLER: SNMP poll successful for #{device}: " +
                "#{total_polled} interfaces polled, #{if_table.size} processed (#{elapsed} seconds)")

      # Update the application
      metadata[:last_poll_duration] = Time.now.to_i - start_time.to_i
      metadata[:last_poll_result] = 0
      metadata[:last_poll_text] = ''
      post_devices = { device => {
        :metadata => metadata,
        :interfaces => interfaces,
        :cpus => cpus,
        :memory => memory,
        :temperature => temperature,
        :psu => psu,
        :fan => fan,
        :devicedata => dev_info,
      } }

      _post_data(post_devices)

    end # End fork
    Process.detach(pid)
    $LOG.info("POLLER: Forked PID #{pid} (#{device})")
  end


  def self._process_interface(device, if_table, if_index, oids, last_values, poller_cfg, influx_is_up)
    oids.dup.each do |oid_text, value|
      series_name = device + '.' + if_index + '.' + oid_text
      series_data = { :value => value.to_s, :time => Time.now.to_i }

      # Take the difference and average it out per second since the last poll
      #   if this OID supposed to be averaged
      # First make sure we have 2 data points -- if not we can't average
      if oid_text =~ poller_cfg[:avg_oid_regex] && last_oids
        avg_series_name = device + '.' + if_index + '.' + poller_cfg[:avg_names][oid_text]
        average = (value.to_i - last_oids[oid_text]) / (Time.now.to_i - last_oids['last_updated'])
        average = average * 8 if series_name =~ /octets/
        avg_series_data = { :value => average, :time => Time.now.to_i }
        # Calculate utilization if we're a bps OID
        if avg_series_name =~ /bps/
          # Fix for interfaces that don't report a valid speed -- set util to 0
          if oids['if_high_speed'].to_i == 0
            util = 0
          else
            util = '%.2f' % (average.to_f / (oids['if_high_speed'].to_i * 1000000) * 100)
            util = 100 if util.to_f > 100
          end
          oids[poller_cfg[:avg_names][oid_text] + '_util'] = util
        end
        # write the average
        unless average < 0
          oids[poller_cfg[:avg_names][oid_text]] = average
          influx_is_up = _write_influxdb(avg_series_name, avg_series_data, poller_cfg) if influx_is_up
        end
      end
    end # End oids.each
    return oids
  end


  def self._query_device_interfaces(ip, poller_cfg)
    SNMP::Manager.open(:host => ip, :community => poller_cfg[:snmpv2_community]) do |session|
      if_table = {}
      session.walk(poller_cfg[:oids][:general].keys) do |row|
        row.each do |vb|
          oid_text = poller_cfg[:oids][:general][vb.name.to_str.gsub(/\.[0-9]+$/,'')]
          if_index = vb.name.to_str[/[0-9]+$/]
          if_table[if_index] ||= {}
          if_table[if_index][oid_text] = vb.value.to_s
          # The following line removes ' characters from the beginning and end of aliases (Linux does this)
          if_table[if_index][oid_text].gsub!(/^'|'$/,'') if oid_text == 'if_alias'
        end
      end
      return if_table
    end
  end


  def self._query_device_info(ip, poller_cfg)
    data = {}
    SNMP::Manager.open(
      :host => ip,
      :community => poller_cfg[:snmpv2_community],
      :mib_dir => 'lib/mibs',
      :mib_modules => [
        'CISCO-PRODUCTS-MIB',
        'JNX-CHAS-DEFINES-MIB',
        'F10-PRODUCTS-MIB',
      ]
    ) do |session|

      session.get("1.3.6.1.2.1.1.1.0").each_varbind do |vb|
        data[:sys_descr] = vb.value.to_s
        if data[:sys_descr] =~ /Cisco/
          data[:vendor] = 'Cisco'
        elsif data[:sys_descr] =~ /Juniper|SRX/
          data[:vendor] = 'Juniper'
        elsif data[:sys_descr] =~ /Force10.*Series: S/m
          data[:vendor] = 'Force10 S-Series'
        elsif data[:sys_descr] =~ /Linux/
          data[:vendor] = 'Linux'
        else
          # If we don't know what type of device this is:
          $LOG.warn("POLLER: Unknown device at #{ip}: #{data[:sys_descr]}")
          data[:vendor] = 'Unknown'
        end
        if sys_descr_regex = poller_cfg[:sys_descr_regex][data[:vendor]]
          if match = data[:sys_descr].match(sys_descr_regex)
            data[:sw_descr] = match[1].strip
            data[:sw_version] = match[2].strip
          end
        end
      end # /session.get

      # Get HW info (model)
      session.get('1.3.6.1.2.1.1.2.0').each_varbind do |vb|
        data[:hw_model] = (vb.value.to_s.split('::')[1] || '').gsub('jnxProductName','')
      end

      # Run though the general and vendor-specific OIDs
      poller_cfg[:device_oids][:general].each do |oid,text|
        session.get(oid).each_varbind { |vb| data[text] = vb.value }
      end
      if vendor_oids = poller_cfg[:device_oids][data[:vendor]]
        vendor_oids.each do |oid,text|
          session.get(oid).each_varbind { |vb| data[text] = vb.value }
        end
      end
    end

    # Manipulate data if needed for transmission via JSON
    data.each do |text,value|
      # SNMP::TimeTicks --> epoch integer
      data[text] = value.to_i / 100 if value.is_a?(SNMP::TimeTicks)
    end

    return data
  end


  def self._query_device_mac(device, ip, poller_cfg, vendor, if_table)
    return [] unless vendor_cfg = poller_cfg[:oids][vendor]
    return [] unless vendor_cfg['mac_address_table'] && vendor_cfg['mac_poll_style']
    mac_table = []

    if vendor_cfg['mac_poll_style'] == 'Juniper'
      # For juniper style polling

      SNMP::Manager.open(:host => ip, :community => poller_cfg[:snmpv2_community]) do |session|
        # Get the conversion hash between dot1q VLAN id and VLAN tag
        dot1q_to_vlan = {}
        session.walk(vendor_cfg['dot1q_to_vlan_tag']) do |row|
          row.each do |vb|
            dot1q_id = vendor_cfg['dot1q_id_regex_vlan'].match( vb.name.to_str )[1]
            dot1q_to_vlan[dot1q_id] = vb.value.to_s
          end
        end
        # Get the conversion hash between dot1q interface id and ifIndex
        dot1q_to_if_index = {}
        session.walk(vendor_cfg['dot1q_to_if_index']) do |row|
          row.each do |vb|
            dot1q_id = vendor_cfg['dot1q_id_regex_if'].match( vb.name.to_str )[1]
            dot1q_to_if_index[dot1q_id] = vb.value.to_s
          end
        end

        # Get the mac addresses!
        session.walk(vendor_cfg['mac_address_table']) do |row|
          row.each do |vb|
            mac = {}

            dot1q_vlan_id = vendor_cfg['dot1q_id_regex_mac'].match( vb.name.to_str )[1]
            dot1q_port_id = vb.value.to_s

            vlan_id = dot1q_to_vlan[dot1q_vlan_id]
            next unless vlan_id

            if_index = dot1q_to_if_index[dot1q_port_id]
            mac_addr = _mac_dec_to_hex( vendor_cfg['mac_address_regex'].match( vb.name.to_str )[1] )

            # If this is an ae0.0 type interface, replace if_index w/ the if_index for ae0 (without the .x)
            if if_table[if_index] && if_table[if_index]['if_name'].match(/\.[0-9]+$/)
              if_table.each do |index,oids|
                # Skip if this is a sub-interface
                next if oids['if_name'].match(/\.[0-9]+$/)
                if if_table[if_index]['if_name'].include?(oids['if_name'])
                  # If it is a match, set the index to the non-sub interface index and break the block
                  if_index = index
                  break;
                end
              end
            end

            mac[:mac] = mac_addr if mac_addr
            mac[:vlan_id] = vlan_id if vlan_id
            mac[:if_index] = if_index if if_index
            mac[:device] = device
            mac[:last_updated] = Time.now.to_i

            mac_table.push(mac)
          end
        end
      end
    elsif vendor_cfg['mac_poll_style'] == 'Cisco'
      # For Cisco style polling
      vlans = []

      SNMP::Manager.open(:host => ip, :community => poller_cfg[:snmpv2_community]) do |session|
        # Get the list of VLANs on the device
        session.walk(vendor_cfg['vlan_status']) do |row|
          row.each do |vb|
            vlan = vendor_cfg['vlan_id_regex_status'].match( vb.name.to_str )[1]
            next if (1002..1005).include?(vlan.to_i) && vendor == 'Cisco' || vb.value.to_s != "1"
            vlans.push(vlan)
          end
        end
      end

      vlans.each do |vlan|
        # Cycle through each VLAN, using it in the SNMP community string to get data from each VLAN
        vlan_community = "#{poller_cfg[:snmpv2_community]}@#{vlan}"

        SNMP::Manager.open(:host => ip, :community => vlan_community) do |session|
          # Get the conversion hash between dot1q interface id and ifIndex
          dot1q_to_if_index = {}
          session.walk(vendor_cfg['dot1q_to_if_index']) do |row|
            row.each do |vb|
              dot1q_id = vendor_cfg['dot1q_id_regex_if'].match( vb.name.to_str )[1]
              dot1q_to_if_index[dot1q_id] = vb.value.to_s
            end
          end

          # Get the mac addresses!
          session.walk(vendor_cfg['mac_address_table']) do |row|
            row.each do |vb|
              mac = {}

              dot1q_port_id = vb.value.to_s

              mac[:mac] = _mac_dec_to_hex( vendor_cfg['mac_address_regex'].match( vb.name.to_str )[1] )
              mac[:vlan_id] = vlan
              mac[:if_index] = dot1q_to_if_index[dot1q_port_id]
              mac[:device] = device
              mac[:last_updated] = Time.now.to_i

              mac_table.push(mac)
            end
          end
        end
      end

    end

    return mac_table
  end


  def self._query_device_fan(device, ip, poller_cfg, vendor)
    return {} unless vendor_cfg = poller_cfg[:oids][vendor]
    return {} unless vendor_cfg['fan_status']
    fan_table = {}

    SNMP::Manager.open(:host => ip, :community => poller_cfg[:snmpv2_community]) do |session|
      if vendor_cfg['fan_description']
        session.walk(vendor_cfg['fan_description']) do |row|
          row.each do |vb|
            fan_index = vendor_cfg['fan_index_regex'].match( vb.name.to_str )[0]
            fan_table[fan_index] ||= {}
            fan_table[fan_index][:description] = vb.value.to_s
          end
        end
      end
      session.walk(vendor_cfg['fan_status']) do |row|
        row.each do |vb|
          fan_index = vendor_cfg['fan_index_regex'].match( vb.name.to_str )[0]
          status, status_text = _normalize_status(vendor, vb.value.to_i, poller_cfg[:status_table])

          fan_table[fan_index] ||= {}
          fan_table[fan_index][:index] = fan_index
          fan_table[fan_index][:device] = device
          fan_table[fan_index][:status] = status
          fan_table[fan_index][:status_text] = status_text
          fan_table[fan_index][:description] ||= "PSU #{fan_index}"
          fan_table[fan_index][:last_updated] = Time.now.to_i
          fan_table[fan_index][:vendor_status] = vb.value.to_i
        end
      end
    end

    return fan_table
  end


  def self._query_device_psu(device, ip, poller_cfg, vendor)
    return {} unless vendor_cfg = poller_cfg[:oids][vendor]
    return {} unless vendor_cfg['psu_status']
    psu_table = {}

    SNMP::Manager.open(:host => ip, :community => poller_cfg[:snmpv2_community]) do |session|
      if vendor_cfg['psu_description']
        session.walk(vendor_cfg['psu_description']) do |row|
          row.each do |vb|
            psu_index = vendor_cfg['psu_index_regex'].match( vb.name.to_str )[0]
            psu_table[psu_index] ||= {}
            psu_table[psu_index][:description] = vb.value.to_s
          end
        end
      end
      session.walk(vendor_cfg['psu_status']) do |row|
        row.each do |vb|
          psu_index = vendor_cfg['psu_index_regex'].match( vb.name.to_str )[0]
          status, status_text = _normalize_status(vendor, vb.value.to_i, poller_cfg[:status_table])

          psu_table[psu_index] ||= {}
          psu_table[psu_index][:index] = psu_index
          psu_table[psu_index][:device] = device
          psu_table[psu_index][:status] = status
          psu_table[psu_index][:status_text] = status_text
          psu_table[psu_index][:description] ||= "Fan #{psu_index}"
          psu_table[psu_index][:last_updated] = Time.now.to_i
          psu_table[psu_index][:vendor_status] = vb.value.to_i
        end
      end
    end

    return psu_table
  end


  def self._query_device_temp(device, ip, poller_cfg, vendor)
    return {} unless vendor_cfg = poller_cfg[:oids][vendor]
    return {} unless vendor_cfg['temp_value']
    temp_table = {}

    SNMP::Manager.open(:host => ip, :community => poller_cfg[:snmpv2_community]) do |session|
      if vendor_cfg['temp_description']
        session.walk(vendor_cfg['temp_description']) do |row|
          row.each do |vb|
            next if vendor_cfg['temp_list_regex'] && !(vendor_cfg['temp_list_regex'] =~ vb.name.to_str)
            temp_index = vendor_cfg['temp_index_regex'].match( vb.name.to_str )[0]
            temp_table[temp_index] ||= {}
            temp_table[temp_index][:description] = vb.value.to_s
          end
        end
      end
      if vendor_cfg['temp_threshold']
        session.walk(vendor_cfg['temp_threshold']) do |row|
          row.each do |vb|
            next if vendor_cfg['temp_list_regex'] && !(vendor_cfg['temp_list_regex'] =~ vb.name.to_str)
            temp_index = vendor_cfg['temp_index_regex'].match( vb.name.to_str )[0]
            temp_table[temp_index] ||= {}
            temp_table[temp_index][:threshold] = vb.value.to_s
          end
        end
      end
      if vendor_cfg['temp_status']
        session.walk(vendor_cfg['temp_status']) do |row|
          row.each do |vb|
            next if vendor_cfg['temp_list_regex'] && !(vendor_cfg['temp_list_regex'] =~ vb.name.to_str)
            temp_index = vendor_cfg['temp_index_regex'].match( vb.name.to_str )[0]
            status, status_text = _normalize_status(vendor, vb.value.to_i, poller_cfg[:status_table])

            temp_table[temp_index] ||= {}
            temp_table[temp_index][:status] = status
            temp_table[temp_index][:status_text] = status_text
            temp_table[temp_index][:vendor_status] = vb.value.to_i
          end
        end
      end
      session.walk(vendor_cfg['temp_value']) do |row|
        row.each do |vb|
          next if vendor_cfg['temp_list_regex'] && !(vendor_cfg['temp_list_regex'] =~ vb.name.to_str)
          temp_index = vendor_cfg['temp_index_regex'].match( vb.name.to_str )[0]

          temp_table[temp_index] ||= {}
          temp_table[temp_index][:index] = temp_index
          temp_table[temp_index][:device] = device
          temp_table[temp_index][:status] ||= 0
          temp_table[temp_index][:status_text] ||= poller_cfg[:status_table]['Pixel'][0]
          temp_table[temp_index][:description] ||= "TEMP #{temp_index}"
          temp_table[temp_index][:last_updated] = Time.now.to_i
          temp_table[temp_index][:temperature] = vb.value.to_i
          # Don't save 0 values for temperature!
          temp_table.delete(temp_index) if vb.value.to_i == 0
        end
      end
    end

    return temp_table
  end


  def self._query_device_cpu(device, ip, poller_cfg, vendor)
    return {} unless vendor_cfg = poller_cfg[:oids][vendor]
    return {} unless vendor_cfg['cpu_util']
    cpu_table = {}
    cpu_hw_ids = {}

    SNMP::Manager.open(:host => ip, :community => poller_cfg[:snmpv2_community]) do |session|
      # Populate cpu_hw_ids if we have an explicit list of CPUs, Cisco style
      if vendor_cfg['cpu_list']
        session.walk(vendor_cfg['cpu_list']) do |row|
          row.each do |vb|
            cpu_index = vendor_cfg['cpu_index_regex'].match( vb.name.to_str )[0]
            cpu_hw_ids[vb.value.to_s] = cpu_index
          end
        end
      end
      if vendor_cfg['cpu_description']
        session.walk(vendor_cfg['cpu_description']) do |row|
          row.each do |vb|
            hw_index = vendor_cfg['cpu_index_regex'].match( vb.name.to_str )[0]
            # Continue only if one of the following occur:
            #   (1) The hw_index was found in the cpu_list oid (Cisco style)
            #   (2) The oid of our hw_index matches our cpu_list regex (Juniper style)
            next unless cpu_hw_ids[hw_index] || vendor_cfg['cpu_list_regex'] =~ vb.name.to_str
            cpu_index = cpu_hw_ids[hw_index] || hw_index
            cpu_table[cpu_index] = {}
            cpu_table[cpu_index][:description] = vb.value.to_s
          end
        end
      end
      session.walk(vendor_cfg['cpu_util']) do |row|
        row.each do |vb|
          cpu_index = vendor_cfg['cpu_index_regex'].match( vb.name.to_str )[0]

          if cpu_table[cpu_index] || vendor_cfg['cpu_list'] || %w{ Linux }.include?(vendor)
            cpu_table[cpu_index] ||= {}
            cpu_table[cpu_index][:device] = device
            cpu_table[cpu_index][:index] = cpu_index
            cpu_table[cpu_index][:last_updated] = Time.now.to_i
            cpu_table[cpu_index][:description] ||= "CPU #{cpu_index}"
            cpu_table[cpu_index][:util] = vb.value.to_i
          end
        end
      end
    end

    return cpu_table
  end


  def self._query_device_mem(device, ip, poller_cfg, vendor)
    return {} unless vendor_cfg = poller_cfg[:oids][vendor]
    return {} unless vendor_cfg['mem_util'] || vendor_cfg['mem_free']
    mem_table = {}

    SNMP::Manager.open(:host => ip, :community => poller_cfg[:snmpv2_community]) do |session|

      if vendor_cfg['mem_description']
        session.walk(vendor_cfg['mem_description']) do |row|
          row.each do |vb|
            # Skip this mem value if a regex is defined and doesn't match
            next if vendor_cfg['mem_list_regex'] && !(vendor_cfg['mem_list_regex'] =~ vb.name.to_str)
            mem_index = vendor_cfg['mem_index_regex'].match( vb.name.to_str )[0]
            mem_table[mem_index] = {}
            mem_table[mem_index][:description] = vb.value.to_s
          end
        end
      end

      if vendor_cfg['mem_util']
        # We can get the utilization directly
        session.walk(vendor_cfg['mem_util']) do |row|
          row.each do |vb|
            # Skip this mem value if a regex is defined and doesn't match
            next if vendor_cfg['mem_list_regex'] && !(vendor_cfg['mem_list_regex'] =~ vb.name.to_str)
            mem_index = vendor_cfg['mem_index_regex'].match( vb.name.to_str )[0]
            mem_table[mem_index][:util] = vb.value.to_i if mem_table[mem_index]
          end
        end

      elsif vendor_cfg['mem_used']
        # We're going to need to calculate utilization, Cisco style (used / used + free)
        session.walk(vendor_cfg['mem_used']) do |row|
          row.each do |vb|
            mem_index = vendor_cfg['mem_index_regex'].match( vb.name.to_str )[0]
            next unless mem_table[mem_index]
            mem_table[mem_index][:used] = vb.value.to_i
          end
        end
        session.walk(vendor_cfg['mem_free']) do |row|
          row.each do |vb|
            mem_index = vendor_cfg['mem_index_regex'].match( vb.name.to_str )[0]
            next unless mem_table[mem_index]
            mem_table[mem_index][:free] = vb.value.to_i
          end
        end
        mem_table.each do |index, data|
          data[:util] = (data[:used].to_f / (data[:used] + data[:free]) * 100).to_i
        end

      elsif vendor_cfg['mem_total']
        # We're going to need to calculate utilization, Linux style ( (total - free) / total )
        session.walk(vendor_cfg['mem_total']) do |row|
          row.each do |vb|
            mem_index = vendor_cfg['mem_index_regex'].match( vb.name.to_str )[0]
            mem_table[mem_index] ||= {}
            mem_table[mem_index][:total] = vb.value.to_i
          end
        end
        session.walk(vendor_cfg['mem_free']) do |row|
          row.each do |vb|
            mem_index = vendor_cfg['mem_index_regex'].match( vb.name.to_str )[0]
            mem_table[mem_index][:free] = vb.value.to_i
          end
        end
        mem_table.each do |index, data|
          data[:util] = ( ( (data[:total].to_f - data[:free]) / data[:total] ) * 100).to_i
        end
      end

    end

    # Clean up data structure -- add metadata & delete temporary calculation values
    mem_table.each do |index, data|
      # Add metadata
      data[:index] = index
      data[:device] = device
      data[:description] ||= "System Memory"
      data[:last_updated] = Time.now.to_i

      # Delete temp calculation values
      data.delete_if {|k,v| [:total,:free,:used].include?(k)}
    end

    return mem_table
  end


  def self._get_last_values(device, if_table)
    request = "/v1/devices?device=#{device}"
    if devices = API.get('core', request, 'POLLER', 'previous data')
      last_values = devices[device] || {}
      last_values.symbolize!
      last_values[:interfaces] ||= {}
      stale_indexes = { device => { :interface => [] } }
      last_values[:interfaces].each do |index,oids|
        oids.each { |name,value| oids[name] = value.to_i_if_numeric }
        stale_indexes[device][:interface].push(index) unless if_table[index]
      end
    else # HTTP request failed
      abort
    end
    return stale_indexes, last_values
  end


  def self._post_data(devices)
    start = Time.now.to_i
    if API.post('core', '/v1/devices', devices, 'POLLER', 'poll results')
      elapsed = Time.now.to_i - start
      $LOG.info("POLLER: POST successful for #{devices.keys[0]} (#{elapsed} seconds)")
    else
      $LOG.error("POLLER: POST failed for #{devices.keys[0]} (#{elapsed} seconds); Aborting")
    end
    abort
  end


  def self._delete_interfaces(data)
    device = data.keys[0]
    count = data[device][:interface].length
    if API.post('core', '/v1/devices/delete/components', data, 'POLLER', 'interfaces to delete')
      $LOG.warn("POLLER: DELETE successful for #{device} (#{count} interfaces removed)")
    else
      $LOG.error("POLLER: POST failed for #{devices.keys[0]} interface removal")
    end
  end


  def self._write_influxdb(series_name, series_data, poller_cfg, retry_count=0)
    InfluxDB::Logging.logger = $LOG
    influxdb = InfluxDB::Client.new(
      poller_cfg[:influx_db],
      :host => poller_cfg[:influx_ip],
      :username => poller_cfg[:influx_user],
      :password => poller_cfg[:influx_pass],
      :retry => 0,
      :read_timeout => 5,
      :open_timeout => 1,
    )

    retry_limit = 2
    retry_delay = 5
    influx_is_up = true
    base_log = "POLLER: InfluxDB request to #{poller_cfg[:influx_ip]} failed."

    begin # Attempt the connection
      influxdb.write_point(series_name, series_data)
    rescue Timeout::Error, Errno::ETIMEDOUT, Errno::EINVAL, Errno::ECONNRESET,
      Errno::ECONNREFUSED, EOFError, Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError, Net::ProtocolError, InfluxDB::Error
      # The request failed; Retry if allowed
      if retry_count <= retry_limit
        retry_count += 1
        retry_log = "Retry ##{retry_count} (limit: #{retry_limit}) in #{retry_delay} seconds."
        $LOG.error("#{base_log} #{retry_log}")
        sleep retry_delay
        influx_is_up = _write_influxdb(series_name, series_data, poller_cfg, retry_count)
      else
        $LOG.error("#{base_log}\n  Retry limit (#{retry_limit}) exceeded; Aborting.")
        return false
      end
    end
    return influx_is_up
  end


  def self._normalize_status(vendor, vendor_status, table)
    status = table[vendor] ? table[vendor][vendor_status] : 0
    status_text = table['Pixel'][status]
    return status, status_text
  end


  def self._mac_dec_to_hex(mac_dec)
    mac_dec.split('.').map { |octet| octet.to_i.to_s(16).rjust(2,'0') }.join(':')
  end

end
