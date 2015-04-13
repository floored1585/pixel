#!/usr/bin/env ruby

require 'yaml'
require_relative 'core_ext/hash'

module Configfile

  def self.retrieve
    config = YAML.load_file(File.expand_path('../../config/settings.yaml', __FILE__))

    # Add in static poller configuration
    config['poller'] ||= {}
    config['poller'].symbolize!

    # This determines which OID names will get turned into per-second averages.
    config['poller'][:avg_oid_regex] = /octets|discards|errors|pkts/

    # 1st match = SW Platform
    # 2nd match = SW Version
    config['poller'][:sys_descr_regex] = {
      'Cisco' => /^[\w\s]+,[\w\s]+\(([\w\s-]+)\),(?: Version)?([\w\s\(\)\.]+),[\w\s\(\)]+$/,
      'Juniper' => /^[\w\s,]+\.[\w\s\-]+,(?: kernel )?(\w+)\s+([\w\.-]+).+$/,
      'Force10 S-Series' => /^Dell ([\w\s]+)$.+Version: ([\w\d\(\)\.]+)/m,
      'Linux' => /Linux [\w\-_]+ ([\w\.\-]+).([\w\.]+)/,
    }

    # These are the OIDs that will get pulled/stored for our interfaces.
    config['poller'][:oids] = {
      :general => {
        '1.3.6.1.2.1.31.1.1.1.1'  => 'if_name',
        '1.3.6.1.2.1.31.1.1.1.6'  => 'if_hc_in_octets',
        '1.3.6.1.2.1.31.1.1.1.10' => 'if_hc_out_octets',
        '1.3.6.1.2.1.31.1.1.1.7'  => 'if_hc_in_ucast_pkts',
        '1.3.6.1.2.1.31.1.1.1.11' => 'if_hc_out_ucast_pkts',
        '1.3.6.1.2.1.31.1.1.1.15' => 'if_high_speed',
        '1.3.6.1.2.1.31.1.1.1.18' => 'if_alias',
        '1.3.6.1.2.1.2.2.1.4'     => 'if_mtu',
        '1.3.6.1.2.1.2.2.1.7'     => 'if_admin_status',
        '1.3.6.1.2.1.2.2.1.8'     => 'if_oper_status',
        '1.3.6.1.2.1.2.2.1.13'    => 'if_in_discards',
        '1.3.6.1.2.1.2.2.1.14'    => 'if_in_errors',
        '1.3.6.1.2.1.2.2.1.19'    => 'if_out_discards',
        '1.3.6.1.2.1.2.2.1.20'    => 'if_out_errors',
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
    config['poller'][:avg_names] = Hash[
      'if_hc_in_octets'     => 'bps_in',
      'if_hc_out_octets'    => 'bps_out',
      'if_in_discards'      => 'discards_in',
      'if_in_errors'        => 'errors_in',
      'if_out_discards'     => 'discards_out',
      'if_out_errors'       => 'errors_out',
      'if_hc_in_ucast_pkts' => 'pps_in',
      'if_hc_out_ucast_pkts'=> 'pps_out',
    ]

    config['poller'][:interesting_names] = {
      'Cisco'       => /^(Po|Te|Gi|Fa)/,
      'Juniper'     => /^(ae|xe|ge|fe)[^.]*$/,
      'Force10 S-Series' => /^(Po|forty|Te|Gi|Fa|Ma)/,
      'Linux'       => /^(swp|eth|bond)[^.]*$/,
    }

    config['poller'][:status_table] = {
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
