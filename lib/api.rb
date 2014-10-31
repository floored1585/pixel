require_relative 'configfile'
require 'net/http'
require 'uri'
require 'json'

module API

  @settings = Configfile.retrieve

  def self.get(dst_component, request, src_component, task, retry_limit=5)
    uri = URI(@settings[dst_component] + request)
    request = Net::HTTP::Get.new(uri)
    response = _execute_request(uri, request, 'GET', src_component, task, retry_limit)
    response ? JSON.parse(response.body) : false
  end

  def self.post(dst_component, request, rawdata, src_component, task, retry_limit=5)
    return false if rawdata.empty?
    uri = URI(@settings[dst_component] + request)
    request = Net::HTTP::Post.new(uri, {'Content-Type' => 'application/json'})
    request.body = JSON.generate(rawdata)
    _execute_request(uri, request, 'POST', src_component, task, retry_limit)
  end

  def self._execute_request(uri, request, req_type, src_component, task, retry_limit, retry_count=0)
    retry_delay = @settings["api_retry_delay_#{req_type}"] || 5
    base_log = "#{src_component}: API request to #{req_type} #{task} failed: #{uri}."

    begin # Attempt the connection
      Net::HTTP.start(uri.host, uri.port, { use_ssl: uri =~ /^https/ } ) { |http| http.request(request) }
    rescue Timeout::Error, Errno::ETIMEDOUT, Errno::EINVAL, Errno::ECONNRESET,
      Errno::ECONNREFUSED, EOFError, Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError, Net::ProtocolError
      # The request failed; Retry if allowed
      if retry_count < retry_limit
        retry_count += 1
        retry_log = "Retry ##{retry_count} (limit: #{retry_limit}) in #{retry_delay} seconds."
        $LOG.error "#{base_log}\n  #{retry_log}"
        sleep retry_delay
        _execute_request(uri, request, req_type, src_component, task, retry_count)
      else
        $LOG.error "#{base_log}\n  Retry limit (#{retry_limit}) exceeded; Aborting."
        return false
      end

    end
  end

end
