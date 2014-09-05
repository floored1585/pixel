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
      metadata = { :worker => Socket.gethostname }

      # get SNMP data from the device
      begin
        if_table = _query_device(ip, poller_cfg)
      rescue RuntimeError, ArgumentError => e
        $LOG.error("POLLER: Error encountered while polling #{device}: #{e}")
        metadata[:last_poll_result] = 1
        post_devices = { device => { :metadata => metadata, :interfaces => {} } }
        _post_data(post_devices)
      end

      InfluxDB::Logging.logger = $LOG
      influxdb = InfluxDB::Client.new(
        poller_cfg[:influx_db],
        :host => poller_cfg[:influx_ip],
        :username => poller_cfg[:influx_user],
        :password => poller_cfg[:influx_pass],
        :retry => 1)

      # TODO: Need to use stale_indexes to delete stuff
      stale_indexes, last_values = _get_last_values(device, if_table)

      # Run through the hash we got from poll, processing the interesting interfaces
      interfaces = {}
      if_table.each do |if_index, oids|
        # Skip if we're not interested in processing this interface
        next unless oids['if_alias'] =~ poller_cfg[:interesting_alias]
        interfaces[if_index] = _process_interface(device, if_index, oids, last_values, influxdb, poller_cfg)
      end
      $LOG.info("SNMP poll successful for #{device}: " + 
                "#{if_table.size} interfaces polled, #{interfaces.size} processed")

      # Update the application
      metadata[:last_poll_duration] = Time.now.to_i - start_time.to_i
      metadata[:last_poll_result] = 0
      metadata[:last_poll_text] = ''
      post_devices = { device => { :metadata => metadata, :interfaces => interfaces } }

      _post_data(post_devices)

    end # End fork
    Process.detach(pid)
    $LOG.info("POLLER: Forked PID #{pid} (#{device})")
  end

  def self._process_interface(device, if_index, oids, last_values, influxdb, poller_cfg)
    oids['if_index'] = if_index
    oids['device'] = device
    oids['last_updated'] = Time.now.to_i

    last_oids = last_values[:interfaces][if_index]

    # Update the last change time if these values changed or don't exist
    %w( if_admin_status if_oper_status ).each do |oid|
      if(!last_oids || oids[oid].to_i != last_oids[oid])
        oids[oid + '_time'] = Time.now.to_i
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
        average = (value.to_i - last_oids[oid_text].to_i) / (Time.now.to_i - last_oids['last_updated'].to_i)
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
          influxdb.write_point(avg_series_name, avg_series_data)
        end
      end
    end # End oids.each
    return oids
  end

  def self._query_device(ip, poller_cfg)
    SNMP::Manager.open(:host => ip, :community => poller_cfg[:snmpv2_community]) do |session|
      if_table = {}
      session.walk(poller_cfg[:oid_numbers].keys) do |row|
        row.each do |vb|
          oid_text = poller_cfg[:oid_numbers][vb.name.to_str.gsub(/\.[0-9]+$/,'')]
          if_index = vb.name.to_str[/[0-9]+$/]
          if_table[if_index] ||= {}
          if_table[if_index][oid_text] = vb.value.to_s
        end
      end
      return if_table
    end
  end

  def self._get_last_values(device, if_table)
    request = "/v1/devices?device=#{device}"
    if devices = API.get('core', request, 'POLLER', 'previous data')
      last_values = devices[device] || {}
      last_values.symbolize!
      last_values[:interfaces] ||= {}
      stale_indexes = []
      last_values[:interfaces].each do |index,oids|
        oids.each { |name,value| oids[name] = to_i_if_numeric(value) }
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

  def self._poller_cfg(settings)
    # Convert poller settings into hash with symbols as keys
    poller_cfg = settings['poller'].dup || {}
    poller_cfg.symbolize!

    # This determines which OID names will get turned into per-second averages.
    poller_cfg[:avg_oid_regex] = /octets|discards|errors|pkts/

    # These are the OIDs that will get pulled/stored for our interfaces.
    poller_cfg[:oid_numbers] = Hash[
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
    ]

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

  def self.to_i_if_numeric(str)
    # This is sort of a hack, but gets shit converted to int
    begin
      ('%.0f' % str.to_s).to_i
    rescue ArgumentError, TypeError
      str
    end
  end

end
