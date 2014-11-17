require_relative 'configfile'
require 'http'
require 'json'

module API

  @settings = Configfile.retrieve

  def self.get(dst_component, request, src_component, task, retry_limit=5)
    url = @settings[dst_component] + request
    response = _execute_request(url, 'GET', src_component, nil, task, retry_limit)
    response ? JSON.parse(response.body) : false
  end

  def self.post(dst_component, request, rawdata, src_component, task, retry_limit=5)
    url = @settings[dst_component] + request
    return false if rawdata.empty?
    _execute_request(url, 'POST', src_component, rawdata, task, retry_limit)
  end

  def self._execute_request(url, req_type, src_component, rawdata, task, retry_limit, retry_count=0)
    retry_delay = @settings["api_retry_delay_#{req_type}"] || 5
    base_log = "#{src_component}: API request to #{req_type} #{task} failed: #{url}"

    begin # Attempt the connection
      if req_type == 'POST'
        response = HTTP.post(url, :body => JSON.generate(rawdata))
      elsif req_type == 'GET'
        response = HTTP.get(url)
      end
      if response.code.to_i >= 200 && response.code.to_i < 400
        return response
      else
        $LOG.error("#{src_component}: Bad response (#{response.code.to_i}) from #{url}")
        raise Net::HTTPBadResponse
      end
    rescue Timeout::Error, Errno::ETIMEDOUT, Errno::EINVAL, Errno::ECONNRESET,
      Errno::ECONNREFUSED, EOFError, Net::HTTPBadResponse, IOError,
      Net::HTTPHeaderSyntaxError, Net::ProtocolError, SocketError
      # The request failed; Retry if allowed
      if retry_count < retry_limit
        retry_count += 1
        retry_log = "Retry ##{retry_count} (limit: #{retry_limit}) in #{retry_delay} seconds."
        $LOG.error "#{base_log}\n  #{retry_log}"
        sleep retry_delay
        _execute_request(url, req_type, src_component, rawdata, task, retry_limit, retry_count)
      else
        $LOG.error "#{base_log}\n  Retry limit (#{retry_limit}) exceeded; Aborting."
        return false
      end

    end
  end

end
