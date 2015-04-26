require 'socket'
require 'snmp'

module Poller


  def self.check_for_work(settings)
    poll_cfg = settings['poller']
    concurrency = poll_cfg[:concurrency] || 10
    hostname = SOcket.gethostname

    if device_names = API.get(
      src: 'poller',
      dst: 'core',
      resource: "/v2/fetch_poll/#{hostname}/#{concurrency}",
      what: "devices to poll for #{hostname}",
    )
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
      $LOG.info("POLLER: Sending device #{device_name} (#{device.poller_uuid})")
      device.send

    end # End fork

    Process.detach(pid)
    $LOG.info("POLLER: Forked PID #{pid} (#{device_name})")
  end


end
