require 'influxdb'
require_relative 'configfile'

module Influx

  @settings = Configfile.retrieve
  @colors = [ 
    '#b2a470', '#92875a', '#ecb796', '#dc8f70', '#716c49', '#d2ed82',
    '#bbe468', '#a1d05d', '#e7cbe6', '#d8aad6', '#a888c2', '#9dc2d3',
    '#649eb9', '#387aa3', '#ecb796', '#dc8f70', '#b2a470', '#92875a',
    '#716c49', '#d2ed82', '#bbe468', '#a1d05d', '#e7cbe6', '#d8aad6',
    '#a888c2', '#9dc2d3', '#649eb9',
  ]

  InfluxDB::Logging.logger = $LOG

  @influxdb = InfluxDB::Client.new(
    @settings['poller']['influx_db'],
    :host => @settings['poller']['influx_ip'],
    :username => @settings['poller']['influx_user'],
    :password => @settings['poller']['influx_pass'],
    :retry => 1)


  def self.query(query, attribute, db, format=nil)
    data = @influxdb.query(query)
    if format == :rickshaw
      # Format for rickshaw AJAX
      response = _transform_rickshaw(data, db, attribute)
    else
      # No special formatting; return raw influxdb
      response = data
    end
    return response
  end


  def self.post_series(name, object)
    data_point = { :value => object, :time => Time.now.to_i }
    @influxdb.write_point(name, data_point)
  end


  def self._transform_rickshaw(original, db, attribute)
    response = []
    counter = 0
    original.each do |series,points|
      description = /#{attribute}\.(.+)$/.match(series)[1]
      device = /(.+)\.#{attribute}/.match(series)[1]
      name = db[attribute.to_sym].filter(:device => device, :description => description).first[:description]
      data = []
      points.each do |point|
        data.unshift({
          'x' => point['time'],
          'y' => point['value'].to_i,
        })
      end
      response.push({
        'color' => @colors[counter],
        'name' => name,
        'data' => data,
      })
      counter += 1
    end
    return response
  end


end
