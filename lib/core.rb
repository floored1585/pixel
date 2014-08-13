#!/usr/bin/env ruby

require_relative 'core_ext/string.rb'

module Pixel
  def get_ints_down(settings, db)
    rows = db[:current].filter(Sequel.like(:if_alias, 'sub%') | Sequel.like(:if_alias, 'bb%'))
    rows = rows.exclude(:device => 'test')
    rows = rows.exclude(:if_oper_status => 1)

    (devices, name_to_index) = _device_map(rows)
    _fill_metadata!(devices, settings, name_to_index)

    # Delete the interface from the hash if its parent is present, to reduce clutter
    devices.each do |device,int|
      int.delete_if { |index,oids| oids[:my_parent] && int[oids[:my_parent]] }
    end
    return devices
  end

  # done
  def get_ints_saturated(settings, db)
    rows = db[:current].filter{ (bps_in_util > 90) | (bps_out_util > 90) }
    rows = rows.exclude(:device => 'test')

    (devices, name_to_index) = _device_map(rows)
    _fill_metadata!(devices, settings, name_to_index)
    return devices
  end

  def get_ints_discarding(settings, db)
    rows = db[:current].filter{Sequel.&(discards_out > 9, ~Sequel.like(:if_alias, 'sub%'))}
    rows = rows.exclude(:device => 'test')
    rows = rows.order(:discards_out).reverse.limit(10)

    (devices, name_to_index) = _device_map(rows)
    _fill_metadata!(devices, settings, name_to_index)
    return devices
  end

  def get_ints_device(settings, db, device)
    rows = db[:current].filter(:device => device)

    (devices, name_to_index) = _device_map(rows)
    _fill_metadata!(devices, settings, name_to_index)
    return devices
  end

  def _device_map(rows)
    devices = {}
    name_to_index = {}

    # If params were passed, use exec_params.  Otherwise just exec.
    columns = rows.columns
    rows.each do |row|

      if_index = row[:if_index]
      device = row[:device]

      devices[device] ||= {}
      name_to_index[device] ||= {}
      devices[device][if_index] = {}

      columns.each do |column|
        devices[device][if_index][column] = row[column].to_s.to_i_if_numeric
        devices[device][if_index][column] = nil if devices[device][if_index][column].to_s.empty?
      end
      name_to_index[device][row[:if_name].downcase] = if_index
    end

    return devices, name_to_index
  end

  def _fill_metadata!(devices, settings, name_to_index)
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
  end
end
