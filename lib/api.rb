require_relative 'configfile'

module API

  @settings = Configfile.retrieve

  def self.get(component, request)
    uri = URI('http://' + @settings['components'][component] + request)
    request = Net::HTTP::Get.new(uri)
    response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
    JSON.parse(response.body)
  end

  def self.post(component, request, rawdata)
    unless rawdata.empty?
      uri = URI('http://' + @settings['components'][component] + request)
      request = Net::HTTP::Post.new(uri, {'Content-Type' => 'application/json'})
      request.body = JSON.generate(rawdata)
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
    end
  end

end
