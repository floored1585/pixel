#
# Pixel is an open source network monitoring system
# Copyright (C) 2016 all Pixel contributors!
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require 'socket'
require 'snmp'

module Poller


  def self.check_for_work(instance, global_config)
    poll_cfg = Poller.get_config(global_config)

    if device_names = API.get(
      src: 'poller',
      dst: 'core',
      resource: "/v2/fetch_poll/#{instance.hostname}/#{poll_cfg[:concurrency]}",
      what: "devices to poll for #{instance.hostname}",
    )
      device_names.each { |device_name, uuid| _poll(device_name, uuid, instance, poll_cfg) }
      return 200 # Doesn't do any error checking here
    else # HTTP request failed
      return 500
    end
  end


  def self._poll(device_name, uuid, instance, poll_cfg)
    pid = fork do
      # Get current values
      device = Device.fetch(device_name, ['all'])

      # Poll the device; send data back to core
      if device.poll(worker: instance.hostname, uuid: uuid, poll_cfg: poll_cfg)
        $LOG.info("POLLER: Finished polling #{device_name}, processing...")
        influx_start = Time.now.to_i
        device.write_influxdb
        influx_total = Time.now.to_i - influx_start
        $LOG.info("POLLER: InfluxDB data saved for #{device_name} in #{influx_total} seconds.")
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


  def self.get_config(global_config)
    config = {}

    config[:concurrency] = global_config.poller_concurrency.value
    config[:influx_ip] = global_config.influx_ip.value
    config[:influx_user] = global_config.influx_user.value
    config[:influx_pass] = global_config.influx_pass.value
    config[:influx_db_name] = global_config.influx_db_name.value
    config[:snmpv2_community] = global_config.snmpv2_community.value

    # interesting_description is the regex that determines whether or not
    # we process & store data, based on the interface description.
    config[:interesting_description] = /^trn__|^bb__|^acc__|^sub(\[|__)/

    # This determines which OID names will get turned into per-second averages.
    config[:avg_oid_regex] = /octets|discards|errors|pkts/

    # 1st match = SW Platform
    # 2nd match = SW Version
    config[:sys_descr_regex] = {
      'Cisco' => /^[\w\s]+,[\w\s]+\(([\w\s-]+)\),(?: Version)?([\w\s\(\)\.]+),[\w\s\(\)]+$/,
      'Juniper' => /^[\w\s,]+\.[\w\s\-]+,(?: kernel )?(\w+)\s+([\w\.-]+).+$/,
      'Force10 S-Series' => /^Dell ([\w\s]+)$.+Version: ([\w\d\(\)\.]+)/m,
      'Linux' => /Linux [\w\-_]+ ([\w\.\-]+).([\w\.]+)/,
    }

    # These are the OIDs that will get pulled/stored for our interfaces.
    config[:oids] = {
      :general => {
        '1.3.6.1.2.1.31.1.1.1.1'  => 'name',
        '1.3.6.1.2.1.31.1.1.1.6'  => 'hc_in_octets',
        '1.3.6.1.2.1.31.1.1.1.10' => 'hc_out_octets',
        '1.3.6.1.2.1.31.1.1.1.7'  => 'hc_in_ucast_pkts',
        '1.3.6.1.2.1.31.1.1.1.11' => 'hc_out_ucast_pkts',
        '1.3.6.1.2.1.31.1.1.1.15' => 'high_speed',
        '1.3.6.1.2.1.31.1.1.1.18' => 'description',
        '1.3.6.1.2.1.2.2.1.4'     => 'mtu',
        '1.3.6.1.2.1.2.2.1.7'     => 'admin_status',
        '1.3.6.1.2.1.2.2.1.8'     => 'oper_status',
        '1.3.6.1.2.1.2.2.1.13'    => 'in_discards',
        '1.3.6.1.2.1.2.2.1.14'    => 'in_errors',
        '1.3.6.1.2.1.2.2.1.19'    => 'out_discards',
        '1.3.6.1.2.1.2.2.1.20'    => 'out_errors',
      },
      'Juniper' => {
        'cpu_index_regex' => /([0-9]+\.?){4}$/,
        'cpu_description' => '1.3.6.1.4.1.2636.3.1.13.1.5',
        'cpu_util'        => '1.3.6.1.4.1.2636.3.1.13.1.8',
        'cpu_list_regex'  => /[97](\.\d+){3}$/,
        'mem_index_regex' => /([0-9]+\.?){4}$/,
        'mem_description' => '1.3.6.1.4.1.2636.3.1.13.1.5',
        'mem_util'        => '1.3.6.1.4.1.2636.3.1.13.1.11',
        'mem_list_regex'  => /[97](\.\d+){3}$/,
        'temp_index_regex'=> /([0-9]+\.?){4}$/,
        'temp_description'=> '1.3.6.1.4.1.2636.3.1.13.1.5',
        'temp_temperature'=> '1.3.6.1.4.1.2636.3.1.13.1.7',
        'psu_index_regex' => /([0-9]+\.?){3}$/,
        'psu_description' => '1.3.6.1.4.1.2636.3.1.13.1.5.2',
        'psu_vendor_status'   => '1.3.6.1.4.1.2636.3.1.13.1.6.2',
        'fan_index_regex' => /([0-9]+\.?){3}$/,
        'fan_description' => '1.3.6.1.4.1.2636.3.1.13.1.5.4',
        'fan_vendor_status'   => '1.3.6.1.4.1.2636.3.1.13.1.6.4',
        'dot1q_to_vlan_tag'   => '1.3.6.1.4.1.2636.3.40.1.5.1.5.1.5',
        'dot1q_to_if_index'   => '1.3.6.1.2.1.17.1.4.1.2',
        'dot1q_id_regex_vlan' => /([0-9]+\.?)$/,
        'dot1q_id_regex_if'   => /([0-9]+\.?)$/,
        'dot1q_id_regex_mac'  => /(\d+)\.(?:[0-9]+\.?){6}$/,
        'mac_poll_style'      => 'Juniper',
        'mac_address_table'   => '1.3.6.1.2.1.17.7.1.2.2.1.2',
        'mac_address_regex'   => /((?:[0-9]+\.?){6})$/,
        'yellow_alarm'        => '1.3.6.1.4.1.2636.3.4.2.2.1.0',
        'red_alarm'           => '1.3.6.1.4.1.2636.3.4.2.3.1.0',
      },
      'Cisco' => {
        'cpu_index_regex' => /[0-9]+$/,
        'cpu_hw_description'  => '1.3.6.1.2.1.47.1.1.1.1.7',
        'cpu_util'        => '1.3.6.1.4.1.9.9.109.1.1.1.1.7', # 1 minute average
        'cpu_hw_id'       => '1.3.6.1.4.1.9.9.109.1.1.1.1.2',
        'mem_index_regex' => /[0-9]+$/,
        'mem_description' => '1.3.6.1.4.1.9.9.48.1.1.1.2',
        'mem_used'        => '1.3.6.1.4.1.9.9.48.1.1.1.5',
        'mem_free'        => '1.3.6.1.4.1.9.9.48.1.1.1.6',
        'temp_index_regex'=> /[0-9]+$/,
        'temp_description'=> '1.3.6.1.4.1.9.9.13.1.3.1.2',
        'temp_temperature'=> '1.3.6.1.4.1.9.9.13.1.3.1.3',
        'temp_threshold'  => '1.3.6.1.4.1.9.9.13.1.3.1.4',
        'temp_vendor_status'  => '1.3.6.1.4.1.9.9.13.1.3.1.6',
        'psu_index_regex' => /[0-9]+$/,
        'psu_description' => '1.3.6.1.4.1.9.9.13.1.5.1.2',
        'psu_vendor_status'   => '1.3.6.1.4.1.9.9.13.1.5.1.3',
        'fan_index_regex' => /[0-9]+$/,
        'fan_description' => '1.3.6.1.4.1.9.9.13.1.4.1.2',
        'fan_vendor_status'   => '1.3.6.1.4.1.9.9.13.1.4.1.3',
        'mac_poll_style'      => 'Cisco',
        'vlan_status'         => '1.3.6.1.4.1.9.9.46.1.3.1.1.2.1',
        'dot1q_to_if_index'   => '1.3.6.1.2.1.17.1.4.1.2',
        'vlan_id_regex_status'=> /([0-9]+\.?)$/,
        'dot1q_id_regex_if'   => /([0-9]+\.?)$/,
        'mac_address_table'   => '1.3.6.1.2.1.17.4.3.1.2',
        'mac_address_regex'   => /((?:[0-9]+\.?){6})$/,
      },
      'Force10 S-Series'  => {
        'cpu_index_regex' => /[0-9]+$/,
        'cpu_description' => '1.3.6.1.4.1.6027.3.10.1.2.2.1.9',
        'cpu_util'        => '1.3.6.1.4.1.6027.3.10.1.2.9.1.3', # 1 minute average
        'mem_index_regex' => /[0-9]+$/,
        'mem_description' => '1.3.6.1.4.1.6027.3.10.1.2.2.1.9',
        'mem_util'        => '1.3.6.1.4.1.6027.3.10.1.2.9.1.5',
        'temp_index_regex'=> /[0-9]+$/,
        'temp_description'=> '1.3.6.1.4.1.6027.3.10.1.2.2.1.9',
        'temp_temperature'=> '1.3.6.1.4.1.6027.3.10.1.2.2.1.14',
        'psu_index_regex' => /([0-9]+\.?){2}$/,
        'psu_vendor_status'   => '1.3.6.1.4.1.6027.3.10.1.2.3.1.2',
        'fan_index_regex' => /([0-9]+\.?){2}$/,
        'fan_vendor_status'   => '1.3.6.1.4.1.6027.3.10.1.2.4.1.2',
      },
      'Linux' => {
        'cpu_index_regex' => /[0-9]+$/,
        'cpu_util'        => '1.3.6.1.2.1.25.3.3.1.2',
        'mem_index_regex' => /[0-9]+$/,
        'mem_total'       => '1.3.6.1.4.1.2021.4.5',
        'mem_free'        => '1.3.6.1.4.1.2021.4.6',
        'temp_index_regex'=> /[0-9]+$/,
        'temp_description'=> '1.3.6.1.4.1.2021.13.16.2.1.2.41',
        'temp_temperature'=> '1.3.6.1.4.1.2021.13.16.2.1.3.2',
      },
    }

    # This is where we define what the averages will be named
    config[:avg_names] = Hash[
      'hc_in_octets'     => 'bps_in',
      'hc_out_octets'    => 'bps_out',
      'in_discards'      => 'discards_in',
      'in_errors'        => 'errors_in',
      'out_discards'     => 'discards_out',
      'out_errors'       => 'errors_out',
      'hc_in_ucast_pkts' => 'pps_in',
      'hc_out_ucast_pkts'=> 'pps_out',
    ]

    config[:interesting_names] = {
      'Cisco'       => /^(Po|Te|Gi|Fa)/,
      'Juniper'     => /^(ae|xe|ge|fe)[^.]*$/,
      'Force10 S-Series' => /^(Po|forty|Te|Gi|Fa|Ma)/,
      'Linux'       => /^(swp|eth|bond)[^.]*$/,
    }

    config[:status_table] = {
      'Pixel' => {
        0 => 'Unknown',
        1 => 'OK',
        2 => 'Problem',
        3 => 'Missing',
      },
      'Cisco' => {
        1 => 1, # normal
        2 => 2, # warning
        3 => 2, # critical
        4 => 2, # shutdown
        5 => 3, # notPresent
        6 => 2, # notFunctioning
      },
      'Juniper' => {
        1 => 2, # Unknown
        2 => 1, # Up and running
        3 => 2, # Ready to run, not running yet
        4 => 2, # Held in reset, not ready yet
        5 => 1, # Running at Full Speed (valid for fans only)
        6 => 2, # Down or off (for power supply)
        7 => 1, # Running as a standby (Backup)
      },
      'Force10 S-Series' => {
        1 => 1, # normal(1), (on for fans)
        2 => 2, # warning(2), (off for fans)
        3 => 2, # critical(3),
        4 => 2, # shutdown(4),
        5 => 3, # notPresent(5),
        6 => 2, # notFunctioning(6),
      },
    }

    return config
  end


end
