require 'socket'
require 'snmp'

module Poller


  def self.check_for_work(settings)
    poll_cfg = settings['poller']
    concurrency = poll_cfg[:concurrency] || 10
    request = "/v2/fetch_poll/#{Socket.gethostname}/#{concurrency}"

    if device_names = API.get('core', request, 'POLLER', 'devices to poll', 0)
      device_names.each { |device_name| _poll(device_name) }
      return 200 # Doesn't do any error checking here
    else # HTTP request failed
      return 500
    end
  end


  def self._poll(device_name)
    pid = fork do
      device = Device.new(device_name)

      # Get current values
      device.populate(:all => true)

      # Poll the device; send data back to core
      if device.poll(worker: Socket.gethostname)
        device.send
      else
        $LOG.error("POLLER: Poll failed for #{device_name}")
      end

    end # End fork

    Process.detach(pid)
    $LOG.info("POLLER: Forked PID #{pid} (#{device_name})")
  end


end
