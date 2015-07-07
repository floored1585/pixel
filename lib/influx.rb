require 'influxdb'
require_relative 'configfile'

module Influx

  poll_cfg = Configfile.retrieve['poller'] || {}

  @colors = [ 
    '#b2a470', '#92875a', '#ecb796', '#dc8f70', '#716c49', '#d2ed82',
    '#bbe468', '#a1d05d', '#e7cbe6', '#d8aad6', '#a888c2', '#9dc2d3',
    '#649eb9', '#387aa3', '#ecb796', '#dc8f70', '#b2a470', '#92875a',
    '#716c49', '#d2ed82', '#bbe468', '#a1d05d', '#e7cbe6', '#d8aad6',
    '#a888c2', '#9dc2d3', '#649eb9',
  ]

  $LOG ||= Logger.new(STDOUT)
  InfluxDB::Logging.logger = $LOG

  @influxdb = InfluxDB::Client.new(
    poll_cfg[:influx_db],
    :host => poll_cfg[:influx_ip],
    :username => poll_cfg[:influx_user],
    :password => poll_cfg[:influx_pass],
    :read_timeout => 5,
    :open_timeout => 1,
    :retry => 1,
  )


  def self.query(query, attribute, db, format=nil)
    begin
      data = @influxdb.query(query)
    rescue Timeout::Error, Errno::ETIMEDOUT, Errno::EINVAL, Errno::ECONNRESET, Net::ReadTimeout,
      Errno::ECONNREFUSED, EOFError, Net::HTTPBadResponse, IOError, Errno::EPIPE,
      Net::HTTPHeaderSyntaxError, Net::ProtocolError, SocketError, OpenSSL::SSL::SSLError
      $LOG.error "CORE: Error polling InfluxDB!"
      data = {}
    end
    if format == :rickshaw
      # Format for rickshaw AJAX
      response = _transform_rickshaw(data, db, attribute)
    else
      # No special formatting; return raw influxdb
      response = data
    end
    return response
  end


  def self.post(series:, value:, time: Time.now.to_i)
    data_point = { :value => value, :time => time }

    begin # Attempt the connection
      @influxdb.write_point(series, data_point)
      return true
    rescue Timeout::Error, Errno::ETIMEDOUT, Errno::EINVAL, Errno::ECONNRESET,
      Errno::ECONNREFUSED, EOFError, Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError, Net::ProtocolError, InfluxDB::Error => e
      $LOG.error("INFLUXDB: #{e}")
      return false
    end

  end


  def self._transform_rickshaw(original, db, attribute)
    response = []
    counter = 0
    original.each do |series,points|
      index = /#{attribute}\.([\.\d]+)\.[^\.]+$/.match(series)[1]
      device = /(.+)\.#{attribute}/.match(series)[1]
      row = db[:component].where(:device => device, :index => index).
        natural_join(attribute.to_sym).first
      next unless row
      description = row[:description]
      data = []
      points.each do |point|
        data.unshift({
          'x' => point['time'],
          'y' => point['value'].to_i,
        })
      end
      response.push({
        'color' => @colors[counter],
        'name' => description,
        'data' => data,
      })
      counter += 1
    end
    return response
  end


end
