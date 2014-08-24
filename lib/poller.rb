module Poller

  def self.check_for_work(settings, db)
    concurrency = settings['poller']['concurrency']
    devices = API.get('core', '/v1/devices/fetch_poll' + "?count=#{concurrency}")
    devices.each { |device, attributes| _poll(device, attributes['ip']) }
    return true
  end

  def self._poll(device, ip)
    puts "Polling #{device} at #{ip}"
  end

end
