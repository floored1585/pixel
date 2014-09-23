require 'influxdb'
require_relative 'configfile'

module Influx

  @settings = Configfile.retrieve
  @colors = [
    "#C04D67", "#A9CA7D", "#33865F", "#EEA8A4", "#A6D96A",
    "#F46D43", "#FDAE61", "#D9EF8B", "#66BD63", "#1A9850",
    "#C04D67", "#A9CA7D", "#33865F", "#EEA8A4", "#A6D96A",
    "#F46D43", "#FDAE61", "#D9EF8B", "#66BD63", "#1A9850",
    "#C04D67", "#A9CA7D", "#33865F", "#EEA8A4", "#A6D96A",
    "#F46D43", "#FDAE61", "#D9EF8B", "#66BD63", "#1A9850",
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
      index = /#{attribute}\.(.+)\.util/.match(series)[1]
      device = /(.+)\.#{attribute}/.match(series)[1]
      name = db[attribute.to_sym].filter(:device => device, :index => index).first[:description]
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
