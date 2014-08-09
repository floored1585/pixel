#!/usr/bin/env ruby

module Pixel
  def populate(pg, query, opts = {})

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

      @@settings['pg_attrs'].each do |attr| 
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
        oids['stale'] = time_since_poll if time_since_poll > @@settings['stale_timeout']

        if oids['ppsOut'] && oids['ppsOut'] != 0
          oids['discardsOut_pct'] = '%.2f' % (oids['discardsOut'].to_f / oids['ppsOut'] * 100)
        end

        # Populate 'linkType' value (Backbone, Access, etc...)
        oids['ifAlias'].match(/^[a-z]+(__|\[)/) do |type|
          type = type.to_s.gsub(/(_|\[)/,'')
            oids['linkType'] = @@settings['link_types'][type]
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

  def humanize_time secs
    [[60, :seconds], [60, :minutes], [24, :hours], [1000, :days]].map{ |count, name|
      if secs > 0
        secs, n = secs.divmod(count)
        if n.to_i > 1
          "#{n.to_i} #{name}"
        else
          "#{n.to_i} #{name.to_s.gsub(/s$/,'')}"
        end
      end
    }.compact[-1]
  end

  def full_title(page_title)
    base_title = "Pixel"
    if page_title.empty?
      base_title
    else
      "#{base_title} | #{page_title}"
    end
  end

  def tr_attributes(oids, opts={})
    attributes = [
      "data-toggle='tooltip'",
      "data-container='body'",
      "title='index: #{oids['if_index']}'",
      "data-rel='tooltip-left'",
        "data-pxl-index='#{oids['if_index']}'"
    ]
    attributes.push "data-pxl-parent='#{oids['myParent']}'" if oids['isChild'] && opts[:hl_relation]
    classes = []

    if oids['isChild']
      classes.push("#{oids['myParent']}_child") if opts[:hl_relation]
      classes.push('panel-collapse collapse out') if opts[:hide_if_child]
      classes.push('pxl-child-tr') if opts[:hl_relation]
    end

    attributes.join(' ') + " class='#{classes.join(' ')}'"
  end

  def bps_cell(direction, oids, opts={})
    # If bpsIn/Out doesn't exist, return blank
    return '' unless oids['bps' + direction] && oids['linkUp']
    util = ('%.3g' % oids["bps#{direction}_util"]) + '%'
    util.gsub!(/\.[0-9]+/,'') if opts[:compact]
    traffic = number_to_human(oids['bps' + direction], :bps, true)
    return traffic if opts[:bps_only]
    return util if opts[:pct_only]
  end
end
