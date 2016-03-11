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

require 'net/http'
require 'uri'
require 'json'
require 'yaml'

$LOG ||= Logger.new(STDOUT)

module API

  @core_url = YAML.load_file(File.expand_path('../../config/config.yaml', __FILE__))['core']

  def self.get(src:, dst:, resource:, what:, retries: 5, delay: 5)
    uri, http = get_http(dst, resource)
    req = Net::HTTP::Get.new(uri.request_uri)

    begin
      response = http.request(req)
      code = response.code
    rescue Timeout::Error, Errno::ETIMEDOUT, Errno::EINVAL, Errno::ECONNRESET, Net::ReadTimeout,
      Errno::ECONNREFUSED, EOFError, Net::HTTPBadResponse, IOError, Errno::EPIPE,
      Net::HTTPHeaderSyntaxError, Net::ProtocolError, SocketError, OpenSSL::SSL::SSLError => e
      code = e
    end

    # Return an object if successful
    return JSON.load(response.body) if response.kind_of? Net::HTTPSuccess

    # If the request failed, retry after the appropriate delay if there are any retries
    #   left, otherwise return false
    if retries > 0
      $LOG.warn(
        "#{src.upcase}: API request to GET #{what} from #{dst.upcase} failed. " +
        "Retries left: #{retries}. Next retry in #{delay} seconds (#{code})"
      )
      sleep delay
      get(
        src: src, dst: dst, resource: resource, what: what,
        retries: (retries - 1), delay: delay
      )
    else
      $LOG.error(
        "#{src.upcase}: API request to GET #{what} from #{dst.upcase} failed. " +
        "No retries left; aborting (#{code})"
      )
      return false
    end
  end


  def self.post(src:, dst:, resource:, what:, data:, retries: 5, delay: 5)
    # Convert data to JSON if it's not already a string
    data = data.to_json unless data.class == String

    uri, http = get_http(dst, resource)
    req = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' =>'application/json'})
    req.body = data

    begin
      response = http.request(req)
      code = response.code
    rescue Timeout::Error, Errno::ETIMEDOUT, Errno::EINVAL, Errno::ECONNRESET, Net::ReadTimeout,
      Errno::ECONNREFUSED, EOFError, Net::HTTPBadResponse, IOError, Errno::EPIPE,
      Net::HTTPHeaderSyntaxError, Net::ProtocolError, SocketError, OpenSSL::SSL::SSLError => e
      code = e
    end

    return true if response.kind_of? Net::HTTPSuccess

    # If the request failed, retry after the appropriate delay if there are any retries
    #   left, otherwise return false
    if retries > 0
      $LOG.warn(
        "#{src.upcase}: API request to POST #{what} from #{dst.upcase} failed. " +
        "Retries left: #{retries}. Next retry in #{delay} seconds (#{code})"
      )
      sleep delay
      post(
        src: src, dst: dst, resource: resource, what: what,
        data: data, retries: (retries - 1), delay: delay,
      )
    else
      $LOG.error(
        "#{src.upcase}: API request to POST #{what} from #{dst.upcase} failed. " +
        "No retries left; aborting (#{code})"
      )
      return false
    end
  end


  def self.get_http(dst, resource)
    url = @core_url.to_s.gsub(/\/$/,'') + resource.to_s
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if url =~ /^https/
    http.read_timeout = 300
    return uri, http
  end


end
