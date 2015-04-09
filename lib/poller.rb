require 'socket'
require 'influxdb'
require 'snmp'
require 'net/http'
require 'json'
require 'uri'
require_relative 'core_ext/hash'

module Poller


  def self.check_for_work(settings)
    poll_cfg = settings['poller']
    concurrency = poll_cfg['concurrency']
    request = "/v1/devices/fetch_poll?count=#{concurrency}&hostname=#{Socket.gethostname}"

    if device_names = API.get('core', request, 'POLLER', 'devices to poll', 0)
      device_names.each { |device_name| _poll(poll_cfg, device_name) }
      return 200 # Doesn't do any error checking here
    else # HTTP request failed
      return 500
    end
  end


  def self._poll(poll_cfg, device_name)
    pid = fork do
      start_time = Time.now
      metadata = { :worker => Socket.gethostname }

      # get SNMP data from the device
      start = Time.now
      start_total = Time.now

      device = Device.new(device_name, poll_cfg: poll_cfg)

      # Get current values
      device.populate(:all => true)


      # Poll the device; send data back to core
      if device.poll(poller_cfg, worker: Socket.gethostname)
        device.send
      else
        $LOG.error("POLLER: Poll failed for #{device_name}")
      end

      # TODO: Need to use stale_indexes to delete stuff
      stale_indexes, last_values = _get_last_values(device, if_table)
      _delete_interfaces(stale_indexes) if stale_indexes[device][:interface].length > 0

    end # End fork
    Process.detach(pid)
    $LOG.info("POLLER: Forked PID #{pid} (#{device})")
  end


  def self._delete_interfaces(data)
    device = data.keys[0]
    count = data[device][:interface].length
    if API.post('core', '/v1/devices/delete/components', data, 'POLLER', 'interfaces to delete')
      $LOG.warn("POLLER: DELETE successful for #{device} (#{count} interfaces removed)")
    else
      $LOG.error("POLLER: POST failed for #{devices.keys[0]} interface removal")
    end
  end


end
