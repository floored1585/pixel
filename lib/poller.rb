require 'socket'
require 'influxdb'
require 'snmp'
require 'net/http'
require 'json'
require 'uri'

module Poller

  def self.check_for_work(settings, db)
    concurrency = settings['poller']['concurrency']
    hostname = Socket.gethostname
    request = '/v1/devices/fetch_poll'
    request = request + "?count=#{concurrency}"
    request = request + "&hostname=#{hostname}"

    devices = API.get('core', request)
    devices.each { |device, attributes| _poll(settings, device, attributes['ip']) }
    return true
  end

  def self._poll(settings, device, ip)
    # Convert poller settings into hash with symbols as keys
    poller_cfg = settings['poller'].each_with_object({}){|(k,v), h| h[k.to_sym] = v}

    beginning = Time.now

    # Columns that are in PG but not polled or calculated
    pg_extras = %w(
      last_updated
      ifAdminStatus_time
      ifOperStatus_time
      bpsIn_util
      bpsOut_util
    )

    # This determines which OID names will get turned into per-second averages.
    avg_oid_regex = /octets|discards|errors|pkts/

    # These are the OIDs that will get pulled/stored for our interfaces.
    oid_names = Hash[
      'if_name'        => '1.3.6.1.2.1.31.1.1.1.1',
      'if_hc_in_octets'  => '1.3.6.1.2.1.31.1.1.1.6',
      'if_hc_out_octets' => '1.3.6.1.2.1.31.1.1.1.10',
      'if_hc_in_ucast_pkts' => '1.3.6.1.2.1.31.1.1.1.7',
      'if_hc_out_ucast_pkts' => '1.3.6.1.2.1.31.1.1.1.11',
      'if_high_speed'   => '1.3.6.1.2.1.31.1.1.1.15',
      'if_alias'       => '1.3.6.1.2.1.31.1.1.1.18',
      'if_mtu'         => '1.3.6.1.2.1.2.2.1.4',
      'if_admin_status' => '1.3.6.1.2.1.2.2.1.7',
      'if_oper_status'  => '1.3.6.1.2.1.2.2.1.8',
      'if_in_discards'  => '1.3.6.1.2.1.2.2.1.13',
      'if_in_errors'    => '1.3.6.1.2.1.2.2.1.14',
      'if_out_discards' => '1.3.6.1.2.1.2.2.1.19',
      'if_out_errors'   => '1.3.6.1.2.1.2.2.1.20'
    ]
    # Create the reverse hash of the OIDs above so we can easly get names from keys
    oid_numbers = oid_names.invert

    # This is where we define what the averages will be named
    avg_names = Hash[
      'if_hc_in_octets'  => 'bps_in',
      'if_hc_out_octets' => 'bps_out',
      'if_in_discards'  => 'discards_in',
      'if_in_errors'    => 'errors_in',
      'if_out_discards' => 'discards_out',
      'if_out_errors'   => 'errors_out',
      'if_hc_in_ucast_pkts' => 'pps_in',
      'if_hc_out_ucast_pkts' => 'pps_out'
    ]

    begin # Start exception handling

      pid = fork do

        if_table = {}
        count = nil
        # get SNMP data from the device
        begin
          count, if_table = query_device(ip, poller_cfg[:snmpv2_community], oid_numbers)
        rescue RuntimeError, ArgumentError => e
          puts "Error encountered while polling #{device}: " + e.to_s
          metadata = { :last_poll_result => 1 }
          return_data( {device => { :metadata => metadata }} )
          abort
        end

        influxdb = InfluxDB::Client.new(
          poller_cfg[:influx_db],
          :host => poller_cfg[:influx_ip],
          :username => poller_cfg[:influx_user],
          :password => poller_cfg[:influx_pass],
          :retry => 1)

        stale_indexes = []

        last_values = (API.get('core', "/v1/devices/#{device}"))[device] || {}
        last_values.each do |index,oids|
          oids.each { |name,value| oids[name] = to_i_if_numeric(value) }
          stale_indexes.push(index) unless if_table[index]
        end

        # Run through the hash we got from poll, processing the interesting interfaces
        interfaces = {}
        until if_table.empty?
          if_index, oids = if_table.shift

          # Skip if we're not interested in processing this interface
          next unless oids['if_alias'] =~ poller_cfg[:interesting_alias]

          interfaces[if_index] = oids.dup
          interfaces[if_index]['if_index'] = if_index
          interfaces[if_index]['device'] = device
          interfaces[if_index]['last_updated'] = Time.now.to_i

          # Update the last change time if these values changed.
          %w( if_admin_status if_oper_status ).each do |oid|
            if(!last_values[if_index] || oids[oid].to_i != last_values[if_index][oid])
              interfaces[if_index][oid + '_time'] = Time.now.to_i
            end
          end

          oids.each do |oid_text,value|
            series_name = device + '.' + if_index + '.' + oid_text
            series_data = { :value => value.to_s, :time => Time.now.to_i }

            # Take the difference and average it out per second since the last poll
            #   if this OID supposed to be averaged
            # First make sure we have 2 data points -- if not we can't average
            if oid_text =~ avg_oid_regex && last_values[if_index]
              avg_series_name = device + '.' + if_index + '.' + avg_names[oid_text]
              average = (value.to_i - last_values[if_index][oid_text].to_i) / (Time.now.to_i - last_values[if_index]['last_updated'].to_i)
              average = average * 8 if series_name =~ /octets/
              avg_series_data = { :value => average, :time => Time.now.to_i }
              # Calculate utilization if we're a bps OID
              if avg_series_name =~ /bps/ && oids['if_high_speed'].to_i != 0
                util = '%.2f' % (average.to_f / (oids['if_high_speed'].to_i * 1000000) * 100)
                util = 100 if util.to_f > 100
                interfaces[if_index][avg_names[oid_text] + '_util'] = util
              end
              # write the average
              unless average < 0
                interfaces[if_index][avg_names[oid_text]] = average
                influxdb.write_point(avg_series_name, avg_series_data)
              end
            end
          end
        end # End if_index.each

        # Update the application
        interfaces['metadata'] = {
          :last_poll_duration => Time.now.to_i - beginning.to_i,
          :last_poll_result => 0,
          :last_poll_text => '',
        }
        return_data( {device => interfaces} )
        puts "#{device} polled successfully (#{count} interfaces polled, #{interfaces.keys.size} returned)"

      end # End fork
      Process.detach(pid)
      puts "Forked PID #{pid} (#{device})"

    rescue StandardError => error
      raise error
    end
  end

  def self.query_device(ip, community, oid_numbers)
    SNMP::Manager.open(:host => ip, :community => community) do |session|
      if_table = {}
      count = 0
      session.walk(oid_numbers.keys) do |row|
        count += 1
        row.each do |vb|
          oid_text = oid_numbers[vb.name.to_str.gsub(/\.[0-9]+$/,'')]
          if_index = vb.name.to_str[/[0-9]+$/]
          if_table[if_index] ||= {}
          if_table[if_index][oid_text] = vb.value.to_s
        end
      end
      return count, if_table
    end
  end

  def self.return_data(devices)
    res = API.post('core', '/v1/devices', devices)
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
