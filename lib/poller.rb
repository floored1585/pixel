require 'socket'

module Poller

  def self.check_for_work(settings, db)
    concurrency = settings['poller']['concurrency']
    hostname = Socket.gethostname
    request = '/v1/devices/fetch_poll'
    request = request + "?count=#{concurrency}"
    request = request + "&hostname=#{hostname}"

    devices = API.get('core', request)
    devices.each { |device, attributes| _poll(device, attributes['ip']) }
    return true
  end

  def self._poll(device, ip)
    puts "Polling #{device} at #{ip}"
  end

end
