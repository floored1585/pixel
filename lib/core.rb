#!/usr/bin/env ruby

require_relative 'core_ext/string.rb'

module Pixel
  def interfaces_down(settings,db_handle,opts = {})
    query = "( if_alias LIKE 'sub%' OR if_alias LIKE 'bb%' ) AND if_oper_status != 1"

    interfaces = _return_interfaces(db_handle,query)
    (devices,name_to_index) = _device_map(settings,interfaces)
    metadata = _device_metadata(settings,devices,name_to_index,opts)

    metadata.each do |device,int|
      int.delete_if do |index,oids|
        oids[:my_parent] && int[oids[:my_parent]]
      end 
    end
    return metadata
  end

  # done
  def interfaces_saturated(settings,db_handle,opts = {})
    query = "( bps_in_util > 90 OR bps_out_util > 90 )"
    query_option = "limit"

    interfaces = _return_interfaces(db_handle,query,query_option)
    (devices,name_to_index) = _device_map(settings,interfaces)
    metadata = _device_metadata(settings,devices,name_to_index,opts)
    return metadata
  end

  def interfaces_discarded(settings,db_handle,opts = {})
    query = "discards_out > 9 AND if_alias NOT LIKE 'sub%'"
    query_option = "orderby"

    interfaces = _return_interfaces(db_handle,query,query_option)
    (devices,name_to_index) = _device_map(settings,interfaces)
    metadata = _device_metadata(settings,devices,name_to_index,opts)
    return metadata
  end

  def device_interfaces(settings,db_handle,opts = {})
    device = opts
    query = "device = '#{device}'"

    interfaces = _return_interfaces(db_handle,query)
    (devices,name_to_index) = _device_map(settings,interfaces)
    metadata = _device_metadata(settings,devices,name_to_index,{:device => device})
    return metadata
  end

  # totally aware _return_interfaces is ugly
  # the abstraction with Postgres is weird and may need to
  # be refactored to better encompass options like order by and limit
  def _return_interfaces(db_handle,query, option= {})
    current_table = db_handle[:current]
    if option.eql?("oderby")
      dataset = current_table.where(query).exclude(:device => 'test').order(Sequel.desc(:discards_out)).limit(10).all
    elsif option.eql?("limit")
      dataset = current_table.where(query).exclude(:device => 'test').limit(10).all
    else
      dataset = current_table.where(query).exclude(:device => 'test').all
    end
    return dataset
  end

  def _device_map(settings,interfaces)
    devices = {}
    name_to_index = {}

    # If params were passed, use exec_params.  Otherwise just exec.
    interfaces.each do |row|

      if_index = row[:if_index]
      device = row[:device]

      devices[device] ||= {}
      name_to_index[device] ||= {}
      devices[device][if_index] = {}

      settings['pg_attrs'].each do |attr|
        attr = attr.to_sym
        devices[device][if_index][attr] = row[attr].to_s.to_i_if_numeric
        devices[device][if_index][attr] = nil if devices[device][if_index][attr].to_s.empty?
      end
      name_to_index[device][row[:if_name].downcase] = if_index
    end

    return devices,name_to_index
  end

  def _device_metadata(settings,devices,name_to_index,opts={})
    devices.each do |device,interfaces|
      interfaces.each do |index,oids|
        # Populate 'neighbor' value
        oids[:if_alias].to_s.match(/__[a-zA-Z0-9-_]+__/) do |neighbor|
          interfaces[index][:neighbor] = neighbor.to_s.gsub('__','')
        end

        time_since_poll = Time.now.to_i - oids[:last_updated]
        oids[:stale] = time_since_poll if time_since_poll > settings['stale_timeout']

        if oids[:pps_out] && oids[:pps_out] != 0
          oids[:discards_out_pct] = '%.2f' % (oids[:discards_out].to_f / oids[:pps_out] * 100)
        end

        # Populate 'link_type' value (Backbone, Access, etc...)
        oids[:if_alias].match(/^[a-z]+(__|\[)/) do |type|
          type = type.to_s.gsub(/(_|\[)/,'')
            oids[:link_type] = settings['link_types'][type]
            if type == 'sub'
              oids[:is_child] = true
              # This will return po1 from sub[po1]__gar-k11u1-dist__g1/47
              parent = oids[:if_alias][/\[[a-zA-Z0-9\/-]+\]/].gsub(/(\[|\])/, '')
              if parent && parent_index = name_to_index[device][parent.downcase]
                interfaces[parent_index][:is_parent] = true
                interfaces[parent_index][:children] ||= []
                interfaces[parent_index][:children] << index
                oids[:my_parent] = parent_index
              end
              oids[:my_parent_name] = parent.gsub('po','Po')
            end
        end

        oids[:if_oper_status] == 1 ? oids[:link_up] = true : oids[:link_up] = false
      end
    end

    return devices[opts[:device]] if opts[:device]
    return devices
  end
end
