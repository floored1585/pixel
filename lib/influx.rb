#
# Pixel is an open source network monitoring system
# Copyright (C) 2016 all Pixel contributors!
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require 'influxdb'
require_relative 'config'
require_relative 'poller'

module Influx


  @colors = [ 
    '#b2a470', '#92875a', '#ecb796', '#dc8f70', '#716c49', '#d2ed82',
    '#bbe468', '#a1d05d', '#e7cbe6', '#d8aad6', '#a888c2', '#9dc2d3',
    '#649eb9', '#387aa3', '#ecb796', '#dc8f70', '#b2a470', '#92875a',
    '#716c49', '#d2ed82', '#bbe468', '#a1d05d', '#e7cbe6', '#d8aad6',
    '#a888c2', '#9dc2d3', '#649eb9',
  ]

  $LOG ||= Logger.new(STDOUT)
  InfluxDB::Logging.logger = $LOG


  def self.connect
    config = Config.fetch

    InfluxDB::Client.new(
      config.influx_db_name.value,
      :host => config.influx_ip.value,
      :username => config.influx_user.value,
      :password => config.influx_pass.value,
      :read_timeout => 5,
      :open_timeout => 1,
      :retry => 1,
      :epoch => 's'
    )
  end


  def self.query(query, attribute, db, format=nil)
    @influxdb ||= connect

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


  def self.post(data)
    @influxdb = connect unless @influxdb

    begin # Attempt the connection
      @influxdb.write_points(data)
      return true
    rescue Timeout::Error, Errno::ETIMEDOUT, Errno::EINVAL, Errno::ECONNRESET,
      Errno::ECONNREFUSED, EOFError, Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError, Net::ProtocolError, InfluxDB::Error => e
      $LOG.error("INFLUXDB: #{e}")
      return false
    end
  end


  def self._transform_rickshaw(original, db, attribute)
    transformed = {}
    response = []
    counter = 0
    if original[0] && original[0]['values']
      original[0]['values'].each do |point|
        index = point['index']

        transformed[index] ||= {}
        transformed[index]['name'] ||= point['name']
        transformed[index]['data'] ||= []
        transformed[index]['data'].unshift({
          'x' => point['time'],
          'y' => point['value'].to_i
        })
      end
    end

    counter = 0
    transformed.each do |index, data|
      data['color'] = @colors[counter]
      response.push(data)
      counter += 1
    end
    return response
  end


end
