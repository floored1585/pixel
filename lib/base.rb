#!/usr/bin/env ruby

module Pixel
  def populate(settings, pg, query, opts = {})

    devices = {}
    name_to_index = {}

    # If params were passed, use exec_params.  Otherwise just exec.
    result = opts[:params] ? pg.exec_params(query, opts[:params]) : pg.exec(query)
    result.each do |row|
      if_index = row['if_index']
      device = row['device']

      devices[device] ||= {}
      name_to_index[device] ||= {}
      devices[device][if_index] = {}

      settings['pg_attrs'].each do |attr| 
        devices[device][if_index][attr] = row[attr.downcase].to_s.to_i_if_numeric
        devices[device][if_index][attr] = nil if devices[device][if_index][attr].to_s.empty?
      end

      name_to_index[device][row['ifname'].downcase] = if_index
    end

    devices.each do |device,interfaces|
      interfaces.each do |index,oids|
        # Populate 'neighbor' value
        oids['ifAlias'].to_s.match(/__[a-zA-Z0-9-_]+__/) do |neighbor|
          interfaces[index]['neighbor'] = neighbor.to_s.gsub('__','')
        end

        time_since_poll = Time.now.to_i - oids['last_updated']
        oids['stale'] = time_since_poll if time_since_poll > settings['stale_timeout']

        if oids['ppsOut'] && oids['ppsOut'] != 0
          oids['discardsOut_pct'] = '%.2f' % (oids['discardsOut'].to_f / oids['ppsOut'] * 100)
        end

        # Populate 'linkType' value (Backbone, Access, etc...)
        oids['ifAlias'].match(/^[a-z]+(__|\[)/) do |type|
          type = type.to_s.gsub(/(_|\[)/,'')
            oids['linkType'] = settings['link_types'][type]
            if type == 'sub'
              oids['isChild'] = true
              # This will return po1 from sub[po1]__gar-k11u1-dist__g1/47
              parent = oids['ifAlias'][/\[[a-zA-Z0-9\/-]+\]/].gsub(/(\[|\])/, '')
              if parent && parent_index = name_to_index[device][parent.downcase]
                interfaces[parent_index]['isParent'] = true
                interfaces[parent_index]['children'] ||= []
                interfaces[parent_index]['children'] << index
                oids['myParent'] = parent_index
              end
              oids['myParentName'] = parent.gsub('po','Po')
            end
        end

        oids['ifOperStatus'] == 1 ? oids['linkUp'] = true : oids['linkUp'] = false
      end
    end

    return devices[opts[:device]] if opts[:device]
    return devices
  end
end
