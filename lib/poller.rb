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

    if devices = API.get('core', request, 'POLLER', 'devices to poll')
      devices.each { |device, attributes| _poll(poller_cfg, device, attributes['ip']) }
      return 200 # Doesn't do any error checking here
    else # HTTP request failed
      return 500
    end
  end


  def self._poll(poller_cfg, device, ip)
    pid = fork do
      start_time = Time.now
      if_table = {}
      cpus = {}
      memory = {}
      metadata = { :worker => Socket.gethostname }

      # get SNMP data from the device
      begin
        vendor = _query_device_vendor(ip, poller_cfg)
        cpus = _query_device_cpu(device, ip, poller_cfg, vendor)
        memory = _query_device_mem(device, ip, poller_cfg, vendor)
        if_table = _query_device_interfaces(ip, poller_cfg)
        #puts "#{device} Memory Data:"
        #pp memory
        #puts "\n"
      rescue RuntimeError, ArgumentError => e
        $LOG.error("POLLER: Error encountered while polling #{device}: #{e}")
        metadata[:last_poll_result] = 1
        post_devices = { device => {
          :metadata => metadata,
          :interfaces => {},
          :cpus => {},
          :memory => {},
        } }
        _post_data(post_devices)
      end

      # Delete interfaces we're not interested in
      if_table.delete_if { |index,oids| !(oids['if_alias'] =~ poller_cfg[:interesting_alias]) }
      # Populate name_to_index hash
      name_to_index = {}
      if_table.each { |index,oids| name_to_index[oids['if_name'].downcase] = index }

      cpus.each do |index, data|
        series_name = "#{device}.cpu.#{index}.util"
        series_data = { :value => data[:util], :time => Time.now.to_i }
        _write_influxdb(series_name, series_data, poller_cfg)
      end
      memory.each do |index, data|
        series_name = "#{device}.memory.#{index}.util"
        series_data = { :value => data[:util], :time => Time.now.to_i }
        _write_influxdb(series_name, series_data, poller_cfg)
      end

      # TODO: Need to use stale_indexes to delete stuff
      stale_indexes, last_values = _get_last_values(device, if_table)

      # Run through the hash we got from poll, processing the interesting interfaces
      interfaces = {}
      totals = { 'pps_out' => 0, 'bps_out' => 0, 'discards_out' => 0 }
      if_table.each do |if_index, oids|
        # Call _process_interface to do the heavy lifting
        interfaces[if_index] = _process_interface(device, if_index, oids, last_values, poller_cfg)
        # Update totals
        totals.keys.each { |key| totals[key] += interfaces[if_index][key] || 0 }
        # Find the parent interface if it exists, and transfer its type to child.
        # Otherwise (if we're not a child) look at our own type.
        # I hate this logic, but can't think of a better way to do it.
        parent_iface_match = oids['if_alias'].match(/^[a-z]+\[([\w\/\-\s]+)\]/) || []
        if parent_iface = parent_iface_match[1]
          if parent_index = name_to_index[parent_iface.downcase]
            parent_alias = if_table[parent_index]['if_alias'] 
            oids[:if_type] = parent_alias.match(/^([a-z]+)(__|\[)/)[1]
          else
            $LOG.error("POLLER: Can't find parent interface #{parent_iface} on device #{device} (child: #{oids['if_name']})")
            oids[:if_type] = 'unknown'
          end
        else
          oids[:if_type] = oids['if_alias'].match(/^([a-z]+)(__|\[)/)[1]
        end
      end

      # Push the totals to influx
      totals.keys.each do |key|
        metadata[key.to_sym] = totals[key] # for application
        series_name = "#{device}.#{key}"
        series_data = { :value => totals[key], :time => Time.now.to_i }
        _write_influxdb(series_name, series_data, poller_cfg)
      end
      $LOG.info("SNMP poll successful for #{device}: " + 
                "#{if_table.size} interfaces polled, #{interfaces.size} processed")

      # Update the application
      metadata[:last_poll_duration] = Time.now.to_i - start_time.to_i
      metadata[:last_poll_result] = 0
      metadata[:last_poll_text] = ''
      post_devices = { device => {
        :metadata => metadata,
        :interfaces => interfaces,
        :cpus => cpus,
        :memory => memory,
      } }

      _post_data(post_devices)

    end # End fork
    Process.detach(pid)
    $LOG.info("POLLER: Forked PID #{pid} (#{device})")
  end


  def self._process_interface(device, if_index, oids, last_values, poller_cfg)
    oids['if_index'] = if_index
    oids['device'] = device
    oids['last_updated'] = Time.now.to_i

    last_oids = last_values[:interfaces][if_index]

    # Update the last change time if these values changed or don't exist
    %w( if_admin_status if_oper_status ).each do |oid|
      if(!last_oids || oids[oid].to_i != last_oids[oid])
        oids[oid + '_time'] = Time.now.to_i
      else
        oids[oid + '_time'] = last_oids[oid + '_time']
      end
    end

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
        if avg_series_name =~ /bps/ && oids['if_high_speed'].to_i != 0
          util = '%.2f' % (average.to_f / (oids['if_high_speed'].to_i * 1000000) * 100)
          util = 100 if util.to_f > 100
          oids[poller_cfg[:avg_names][oid_text] + '_util'] = util
        end
        # write the average
        unless average < 0
          oids[poller_cfg[:avg_names][oid_text]] = average
          _write_influxdb(avg_series_name, avg_series_data, poller_cfg)
        end
      end
    end # End oids.each
    return oids
  end


  def self._query_device_interfaces(ip, poller_cfg)
    SNMP::Manager.open(:host => ip, :community => poller_cfg[:snmpv2_community]) do |session|
      if_table = {}
      session.walk(poller_cfg[:oid_numbers][:general].keys) do |row|
        row.each do |vb|
          oid_text = poller_cfg[:oid_numbers][:general][vb.name.to_str.gsub(/\.[0-9]+$/,'')]
          if_index = vb.name.to_str[/[0-9]+$/]
          if_table[if_index] ||= {}
          if_table[if_index][oid_text] = vb.value.to_s
        end
      end
      return if_table
    end
  end


  def self._query_device_vendor(ip, poller_cfg)
    SNMP::Manager.open(:host => ip, :community => poller_cfg[:snmpv2_community]) do |session|
      if_table = {}
      session.get("1.3.6.1.2.1.1.1.0").each_varbind do |vb|
        sys_descr = vb.value.to_s.gsub("\n",' ')
        return 'Cisco' if sys_descr =~ /Cisco/
        return 'Juniper' if sys_descr =~ /Juniper|SRX/
        return 'Force10 S-Series' if sys_descr =~ /Force10.*Series: S/
        # If we don't know what type of device this is:
        $LOG.warn("POLLER: Unknown device at #{ip}: #{sys_descr}")
        return 'Unknown'
      end
    end
  end


  def self._query_device_cpu(device, ip, poller_cfg, vendor)
    return {} unless vendor_cfg = poller_cfg[:oid_numbers][vendor]
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
      session.walk(vendor_cfg['hw_description']) do |row|
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
      session.walk(vendor_cfg['cpu_util']) do |row|
        row.each do |vb|
          cpu_index = vendor_cfg['cpu_index_regex'].match( vb.name.to_str )[0]

          if cpu_table[cpu_index] || vendor_cfg['cpu_list']
            cpu_table[cpu_index] ||= {}
            cpu_table[cpu_index][:device] = device
            cpu_table[cpu_index][:index] = cpu_index
            cpu_table[cpu_index][:last_updated] = Time.now.to_i 
            cpu_table[cpu_index][:description] ||= 'CPU'
            cpu_table[cpu_index][:util] = vb.value.to_s 
          end
        end
      end
    end

    return cpu_table
  end


  def self._query_device_mem(device, ip, poller_cfg, vendor)
    return {} unless vendor_cfg = poller_cfg[:oid_numbers][vendor]
    mem_table = {}

    SNMP::Manager.open(:host => ip, :community => poller_cfg[:snmpv2_community]) do |session|
      session.walk(vendor_cfg['mem_description']) do |row|
        row.each do |vb|
          # Skip this mem value if a regex is defined and doesn't match
          next if vendor_cfg['mem_list_regex'] && !(vendor_cfg['mem_list_regex'] =~ vb.name.to_str)
          mem_index = vendor_cfg['mem_index_regex'].match( vb.name.to_str )[0]
          mem_table[mem_index] = {}
          mem_table[mem_index][:index] = mem_index
          mem_table[mem_index][:device] = device
          mem_table[mem_index][:description] = vb.value.to_s
          mem_table[mem_index][:last_updated] = Time.now.to_i 
        end
      end
      if vendor_cfg['mem_util'] # We can get util directly
        session.walk(vendor_cfg['mem_util']) do |row|
          row.each do |vb|
            # Skip this mem value if a regex is defined and doesn't match
            next if vendor_cfg['mem_list_regex'] && !(vendor_cfg['mem_list_regex'] =~ vb.name.to_str)
            mem_index = vendor_cfg['mem_index_regex'].match( vb.name.to_str )[0]
            mem_table[mem_index][:util] = vb.value.to_i if mem_table[mem_index]
          end
        end
      else # We're going to need to calculate utilization
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
          data[:util] = '%.2f' % (data[:used].to_f / (data[:used] + data[:free]) * 100)
        end
      end
    end

    return mem_table
  end


  def self._get_last_values(device, if_table)
    request = "/v1/devices?device=#{device}"
    if devices = API.get('core', request, 'POLLER', 'previous data')
      last_values = devices[device] || {}
      last_values.symbolize!
      last_values[:interfaces] ||= {}
      stale_indexes = []
      last_values[:interfaces].each do |index,oids|
        oids.each { |name,value| oids[name] = value.to_i_if_numeric }
        stale_indexes.push(index) unless if_table[index]
      end
    else # HTTP request failed
      abort
    end
    return stale_indexes, last_values
  end


  def self._post_data(devices)
    if API.post('core', '/v1/devices', devices, 'POLLER', 'poll results')
      $LOG.info("POLLER: POST successful for #{devices.keys[0]}")
    else
      $LOG.error("POLLER: POST failed for #{devices.keys[0]}; Aborting")
    end
    abort
  end


  def self._write_influxdb(series_name, series_data, poller_cfg, retry_count=0)
    InfluxDB::Logging.logger = $LOG
    influxdb = InfluxDB::Client.new(
      poller_cfg[:influx_db],
      :host => poller_cfg[:influx_ip],
      :username => poller_cfg[:influx_user],
      :password => poller_cfg[:influx_pass],
      :retry => 1)

    retry_limit = 5
    retry_delay = 5
    base_log = "POLLER: InfluxDB request to #{poller_cfg[:influx_ip]} failed."

    begin # Attempt the connection
      influxdb.write_point(series_name, series_data)
    rescue Timeout::Error, Errno::ETIMEDOUT, Errno::EINVAL, Errno::ECONNRESET,
      Errno::ECONNREFUSED, EOFError, Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError, Net::ProtocolError
      # The request failed; Retry if allowed
      if retry_count <= retry_limit
        retry_count += 1
        retry_log = "Retry ##{retry_count} (limit: #{retry_limit}) in #{retry_delay} seconds."
        $LOG.error("#{base_log} #{retry_log}")
        sleep retry_delay
        _write_influxdb(series_name, series_data, poller_cfg, retry_count)
      else
        $LOG.error("#{base_log}\n  Retry limit (#{retry_limit}) exceeded; Aborting.")
        return false
      end
    end
  end


  def self._poller_cfg(settings)
    # Convert poller settings into hash with symbols as keys
    poller_cfg = settings['poller'].dup || {}
    poller_cfg.symbolize!

    # This determines which OID names will get turned into per-second averages.
    poller_cfg[:avg_oid_regex] = /octets|discards|errors|pkts/

    # These are the OIDs that will get pulled/stored for our interfaces.
    poller_cfg[:oid_numbers] = {
      :general => {
        '1.3.6.1.2.1.31.1.1.1.1'  => 'if_name',
        '1.3.6.1.2.1.31.1.1.1.6'  => 'if_hc_in_octets',
        '1.3.6.1.2.1.31.1.1.1.10' => 'if_hc_out_octets',
        '1.3.6.1.2.1.31.1.1.1.7'  => 'if_hc_in_ucast_pkts',
        '1.3.6.1.2.1.31.1.1.1.11' => 'if_hc_out_ucast_pkts',
        '1.3.6.1.2.1.31.1.1.1.15' => 'if_high_speed',
        '1.3.6.1.2.1.31.1.1.1.18' => 'if_alias',
        '1.3.6.1.2.1.2.2.1.4'     => 'if_mtu',
        '1.3.6.1.2.1.2.2.1.7'     => 'if_admin_status',
        '1.3.6.1.2.1.2.2.1.8'     => 'if_oper_status',
        '1.3.6.1.2.1.2.2.1.13'    => 'if_in_discards',
        '1.3.6.1.2.1.2.2.1.14'    => 'if_in_errors',
        '1.3.6.1.2.1.2.2.1.19'    => 'if_out_discards',
        '1.3.6.1.2.1.2.2.1.20'    => 'if_out_errors',
      },
      'Juniper' => {
        'hw_description'  => '1.3.6.1.4.1.2636.3.1.13.1.5',
        'cpu_index_regex' => /([0-9]+\.?){4}$/,
        'cpu_util'        => '1.3.6.1.4.1.2636.3.1.13.1.8',
        'cpu_list_regex'  => /2636\.3\.1\.13\.1\.\d\.[97]/,
        'mem_index_regex' => /([0-9]+\.?){4}$/,
        'mem_description' => '1.3.6.1.4.1.2636.3.1.13.1.5',
        'mem_util'        => '1.3.6.1.4.1.2636.3.1.13.1.11',
        'mem_list_regex'  => /2636\.3\.1\.13\.1\.[0-9]+\.[97]/,
      },
      'Cisco' => {
        'hw_description'  => '1.3.6.1.2.1.47.1.1.1.1.7',
        'cpu_index_regex' => /[0-9]+$/,
        'cpu_util'        => '1.3.6.1.4.1.9.9.109.1.1.1.1.7', # 1 minute average
        'cpu_list'        => '1.3.6.1.4.1.9.9.109.1.1.1.1.2',
        'mem_index_regex' => /[0-9]+$/,
        'mem_description' => '1.3.6.1.4.1.9.9.48.1.1.1.2',
        'mem_used'        => '1.3.6.1.4.1.9.9.48.1.1.1.5',
        'mem_free'        => '1.3.6.1.4.1.9.9.48.1.1.1.6',
      },
      'Force10 S-Series'  => {
        'cpu_index_regex' => /[0-9]+$/,
        'hw_description'  => '1.3.6.1.4.1.6027.3.10.1.2.2.1.9',
        'cpu_util'        => '1.3.6.1.4.1.6027.3.10.1.2.9.1.3', # 1 minute average
        'cpu_list_regex'  => /.*/, # No need to filter
        'mem_index_regex' => /[0-9]+$/,
        'mem_description' => '1.3.6.1.4.1.6027.3.10.1.2.2.1.9',
        'mem_util'        => '1.3.6.1.4.1.6027.3.10.1.2.9.1.5',
      },

    }

    # This is where we define what the averages will be named
    poller_cfg[:avg_names] = Hash[
      'if_hc_in_octets'     => 'bps_in',
      'if_hc_out_octets'    => 'bps_out',
      'if_in_discards'      => 'discards_in',
      'if_in_errors'        => 'errors_in',
      'if_out_discards'     => 'discards_out',
      'if_out_errors'       => 'errors_out',
      'if_hc_in_ucast_pkts' => 'pps_in',
      'if_hc_out_ucast_pkts'=> 'pps_out',
    ]

    return poller_cfg
  end

end
