require 'socket'
require 'snmp'

module Poller


  def self.check_for_work(settings)
    poll_cfg = settings['poller']
    concurrency = poll_cfg[:concurrency] || 10
    request = "/v2/fetch_poll/#{Socket.gethostname}/#{concurrency}"

    if device_names = API.get('core', request, 'POLLER', 'devices to poll', 0)
      device_names.each { |device_name, uuid| _poll(device_name, uuid) }
      return 200 # Doesn't do any error checking here
    else # HTTP request failed
      return 500
    end
  end


  def self._poll(device_name, uuid)
    pid = fork do
      # Get current values
      device = Device.fetch(device_name, :interfaces => true)

      # Poll the device; send data back to core
      if device.poll(worker: Socket.gethostname, uuid: uuid)
        device.write_influxdb
      else
        $LOG.error("POLLER: Poll failed for #{device_name}")
      end

      # Send regardless of success or failure
      device.send

    end # End fork

    Process.detach(pid)
    $LOG.info("POLLER: Forked PID #{pid} (#{device_name})")
  end


end
