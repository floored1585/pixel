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
        # write the average
        unless average < 0
          oids[poller_cfg[:avg_names][oid_text]] = average
          influx_is_up = _write_influxdb(avg_series_name, avg_series_data, poller_cfg) if influx_is_up
        end
      end
    end # End oids.each
    return oids
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
