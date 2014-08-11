module Helper

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

  def bps_cell(direction, oids, opts={:pct_precision => 2})
    pct_precision = opts[:pct_precision]
    # If bpsIn/Out doesn't exist, return blank
    return '' unless oids['bps' + direction] && oids['linkUp']
    util = ("%.3g" % oids["bps#{direction}_util"]) + '%'
    util.gsub!(/\.[0-9]+/,'') if opts[:compact]
    traffic = number_to_human(oids['bps' + direction], :bps, true, '%.3g')
    return traffic if opts[:bps_only]
    return util if opts[:pct_only]
    return "#{util} (#{traffic})"
  end

  def total_bps_cell(interfaces, oids)
    if oids['isChild']
      p_oids = interfaces[oids['myParent']]
      if p_oids && p_oids['bpsIn'] && p_oids['bpsOut']
        p_total = p_oids['bpsIn'] + p_oids['bpsOut']
        me_total = (oids['bpsIn'] || 0) + (oids['bpsOut'] || 0)
        offset = me_total / (oids['ifHighSpeed'].to_f * 1000000) * 10
        return p_total - 20 + offset
      else
        return '0'
      end
    end
    oids['bpsIn'] + oids['bpsOut'] if oids['bpsIn'] && oids['bpsOut']
  end

  def speed_cell(oids)
    return '' unless oids['linkUp']
    number_to_human(oids['ifHighSpeed'] * 1000000, :bps, true, '%.0f')
  end

  def neighbor_link(oids, opts={})
    if oids['neighbor']
      neighbor = oids['neighbor'] ? "<a href='/device/#{oids['neighbor']}'>#{oids['neighbor']}</a>" : oids['neighbor']
      port = oids['ifAlias'][/__[0-9a-zA-Z-.: \/]+$/] || ''
      port.empty? || opts[:device_only] ? neighbor : "#{neighbor} (#{port.gsub('__','')})"
    else
      ''
    end
  end

  def interface_link(settings, oids)
    "<a href='#{settings['grafana_if_dash']}" +
      "?title=#{oids['device']}%20::%20#{CGI::escape(oids['ifName'])}" +
    "&name=#{oids['device']}.#{oids['if_index']}" +
    "&ifSpeedBps=#{oids['ifHighSpeed'].to_i * 1000000 }" +
    "&ifMaxBps=#{[ oids['bpsIn'].to_i, oids['bpsOut'].to_i ].max}" + 
                   "' target='_blank'>" + oids['ifName'] + '</a>'
  end

  def device_link(oids)
    "<a href='/device/#{oids['device']}'>"
  end

  def link_status_color(interfaces,oids)
    return 'grey' if oids['stale']
    return 'red' unless oids['linkUp']
    return 'orange' if !oids['discardsOut'].to_s.empty? && oids['discardsOut'] != 0
    return 'orange' if !oids['errorsIn'].to_s.empty? && oids['errorsIn'] != 0
    # Check children -- return orange unless all children are up
    if oids['isParent']
      oids['children'].each do |child_index|
        return 'orange' unless interfaces[child_index]['linkUp']
      end
    end
    return 'green'
  end

  def link_status_tooltip(interfaces,oids)
    discards = oids['discardsOut'] || 0
    errors = oids['errorsIn'] || 0
    stale_warn = oids['stale'] ? "Last polled: #{humanize_time(oids['stale'])} ago\n" : ''
      discard_warn = discards == 0 ? '' : "#{discards} outbound discards/sec\n"
    error_warn = errors == 0 ? '' : "#{errors} receive errors/sec\n"
    child_warn = ''
    if oids['isParent']
      oids['children'].each do |child_index|
        child_warn = "Child link down\n" unless interfaces[child_index]['linkUp']
      end
    end
    state = oids['linkUp'] ? 'Up' : 'Down'
    time = humanize_time(Time.now.to_i - oids['ifOperStatus_time'])
    return stale_warn + discard_warn + error_warn + child_warn + "#{state} for #{time}"
  end

  def number_to_human(raw, unit, si, format='%.2f')
    i = 0
    units = {
      :bps => [' bps', ' Kbps', ' Mbps', ' Gbps', ' Tbps', ' Pbps', ' Ebps', ' Zbps', ' Ybps'],
      :pps => [' pps', ' Kpps', ' Mpps', ' Gpps', ' Tpps', ' Ppps', ' Epps', ' Zpps', ' Ypps'],
      :si_short => [' b', ' K', ' M', ' G', ' T', ' P', ' E', ' Z', ' Y'],
    }
    step = si ? 1000 : 1024
    while raw >= step do
      raw = raw.to_f / step
      i += 1
    end

    return (sprintf format % raw).to_s + ' ' + units[unit][i]
  end
end
