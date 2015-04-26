require_relative 'configfile'
require 'net/http'
require 'uri'
require 'json'

$LOG ||= Logger.new(STDOUT)

module API

  @settings = Configfile.retrieve


  def self.get(src:, dst:, resource:, what:, retries: 5, delay: 5)
    uri, http = get_http(dst, resource)
    req = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(req)

    # Return an object if successful
    return JSON.load(response.body) if response.kind_of? Net::HTTPSuccess

    # If the request failed, retry after the appropriate delay if there are any retries
    #   left, otherwise return false
    if retries > 0
      $LOG.warn(
        "#{src.upcase}: API request to GET #{what} from #{dst.upcase} failed. " +
        "Retries left: #{retries}. Next retry in #{delay} seconds (#{response.code})"
      )
      sleep delay
      get(
        src: src, dst: dst, resource: resource, what: what,
        retries: (retries - 1), delay: delay
      )
    else
      $LOG.error(
        "#{src.upcase}: API request to GET #{what} from #{dst.upcase} failed. " +
        "No retries left; aborting (#{response.code})"
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

    response = http.request(req)

    return true if response.kind_of? Net::HTTPSuccess

    # If the request failed, retry after the appropriate delay if there are any retries
    #   left, otherwise return false
    if retries > 0
      $LOG.warn(
        "#{src.upcase}: API request to POST #{what} from #{dst.upcase} failed. " +
        "Retries left: #{retries}. Next retry in #{delay} seconds (#{response.code})"
      )
      sleep delay
      post(
        src: src, dst: dst, resource: resource, what: what,
        data: data, retries: (retries - 1), delay: delay,
      )
    else
      $LOG.error(
        "#{src.upcase}: API request to POST #{what} from #{dst.upcase} failed. " +
        "No retries left; aborting (#{response.code})"
      )
      return false
    end
  end


  def self.get_http(dst, resource)
    url = @settings[dst].to_s.gsub(/\/$/,'') + resource.to_s
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if url =~ /^https/
    return uri, http
  end


end
