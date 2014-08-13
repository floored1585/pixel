#!/usr/bin/env ruby

require_relative 'core_ext/string.rb'

module Pixel
  def interfaces_down(settings,db_handle,opts = {})
    query = "( ifalias LIKE 'sub%' OR ifalias LIKE 'bb%' ) AND ifoperstatus != 1"

    interfaces = _return_interfaces(db_handle,query)
    (devices,name_to_index) = _device_map(settings,interfaces)
    metadata = _device_metadata(settings,devices,name_to_index,opts)

    metadata.each do |device,int|
      int.delete_if do |index,oids|
       oids[:myParent] && int[oids[:myParent]]
      end 
    end
    return metadata
  end

  # done
  def interfaces_saturated(settings,db_handle,opts = {})
    query = "( bpsin_util > 90 OR bpsout_util > 90 )"
    query_option = "limit"

    interfaces = _return_interfaces(db_handle,query,query_option)
    (devices,name_to_index) = _device_map(settings,interfaces)
    metadata = _device_metadata(settings,devices,name_to_index,opts)
    return metadata
  end

  def interfaces_discarded(settings,db_handle,opts = {})
    query = "discardsout > 9 AND ifalias NOT LIKE 'sub%'"
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
      dataset = current_table.where(query).exclude(:device => 'test').order(Sequel.desc(:discardsout)).limit(10).all
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
        attr_down = attr.downcase.to_sym
        attr = attr.to_sym
        devices[device][if_index][attr] = row[attr_down].to_s.to_i_if_numeric
        devices[device][if_index][attr] = nil if devices[device][if_index][attr].to_s.empty?
      end
      name_to_index[device][row[:ifname].downcase] = if_index
    end

    return devices,name_to_index
  end

  def _device_metadata(settings,devices,name_to_index,opts={})
    devices.each do |device,interfaces|
      interfaces.each do |index,oids|
        # Populate 'neighbor' value
        oids[:ifAlias].to_s.match(/__[a-zA-Z0-9-_]+__/) do |neighbor|
          interfaces[index][:neighbor] = neighbor.to_s.gsub('__','')
        end

        time_since_poll = Time.now.to_i - oids[:last_updated]
        oids[:stale] = time_since_poll if time_since_poll > settings['stale_timeout']

        if oids[:ppsOut] && oids[:ppsOut] != 0
          oids[:discardsOut_pct] = '%.2f' % (oids[:discardsOut].to_f / oids[:ppsOut] * 100)
        end

        # Populate 'linkType' value (Backbone, Access, etc...)
        oids[:ifAlias].match(/^[a-z]+(__|\[)/) do |type|
          type = type.to_s.gsub(/(_|\[)/,'')
            oids[:linkType] = settings['link_types'][type]
            if type == 'sub'
              oids[:isChild] = true
              # This will return po1 from sub[po1]__gar-k11u1-dist__g1/47
              parent = oids[:ifAlias][/\[[a-zA-Z0-9\/-]+\]/].gsub(/(\[|\])/, '')
              if parent && parent_index = name_to_index[device][parent.downcase]
                interfaces[parent_index][:isParent] = true
                interfaces[parent_index][:children] ||= []
                interfaces[parent_index][:children] << index
                oids[:myParent] = parent_index
              end
              oids[:myParentName] = parent.gsub('po','Po')
            end
        end

        oids[:ifOperStatus] == 1 ? oids[:linkUp] = true : oids[:linkUp] = false
      end
    end

    return devices[opts[:device]] if opts[:device]
    return devices
  end
end
