require 'socket'
require 'snmp'

module Poller


  def self.check_for_work(settings, instance)
    poll_cfg = settings['poller']
    concurrency = poll_cfg[:concurrency] || 10

    if device_names = API.get(
      src: 'poller',
      dst: 'core',
      resource: "/v2/fetch_poll/#{instance.hostname}/#{concurrency}",
      what: "devices to poll for #{instance.hostname}",
    )
      device_names.each { |device_name, uuid| _poll(device_name, uuid, instance) }
      return 200 # Doesn't do any error checking here
    else # HTTP request failed
      return 500
    end
  end


  def self._poll(device_name, uuid, instance)
    pid = fork do
      # Get current values
      device = Device.fetch(device_name, ['all'])

      # Poll the device; send data back to core
      if device.poll(worker: instance.hostname, uuid: uuid)
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
