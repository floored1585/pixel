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
      "title='index: #{oids[:if_index]}'",
      "data-rel='tooltip-left'",
        "data-pxl-index='#{oids[:if_index]}'"
    ]
    attributes.push "data-pxl-parent='#{oids[:my_parent]}'" if oids[:is_child] && opts[:hl_relation]
    classes = []

    if oids[:is_child]
      classes.push("#{oids[:my_parent]}_child") if opts[:hl_relation]
      classes.push('panel-collapse collapse out') if opts[:hide_if_child]
      classes.push('pxl-child-tr') if opts[:hl_relation]
    end

    attributes.join(' ') + " class='#{classes.join(' ')}'"
  end

  def bps_cell(direction, oids, opts={:pct_precision => 2})
    pct_precision = opts[:pct_precision]
    # If bps_in/Out doesn't exist, return blank
    return '' unless oids["bps_#{direction}".to_sym] && oids[:link_up]
    util = ("%.3g" % oids["bps_#{direction}_util".to_sym]) + '%'
    util.gsub!(/\.[0-9]+/,'') if opts[:compact]
    traffic = number_to_human(oids["bps_#{direction}".to_sym], :bps, true, '%.3g')
    return traffic if opts[:bps_only]
    return util if opts[:pct_only]
    return "#{util} (#{traffic})"
  end

  def total_bps_cell(interfaces, oids)
    # If interface is child, set total to just under parent total,
    # so that the interface is sorted to sit directly under parent
    # when tablesorter runs.
    if oids[:is_child]
      p_oids = interfaces[oids[:my_parent]]
      if p_oids && p_oids[:bps_in] && p_oids[:bps_out]
        p_total = p_oids[:bps_in] + p_oids[:bps_out]
        me_total = (oids[:bps_in] || 0) + (oids[:bps_out] || 0)
        offset = me_total / (oids[:if_high_speed].to_f * 1000000) * 10
        return p_total - 20 + offset
      else
        return '0'
      end
    end
    # If not child, just return the total bps
    oids[:bps_in] + oids[:bps_out] if oids[:bps_in] && oids[:bps_out]
  end

  def speed_cell(oids)
    return '' unless oids[:link_up]
    speed_in_bps = oids[:if_high_speed] * 1000000
    number_to_human(speed_in_bps, :bps, true, '%.0f')
  end

  def neighbor_link(oids, opts={})
    if oids[:neighbor]
      neighbor = oids[:neighbor] ? "<a href='/device/#{oids[:neighbor]}'>#{oids[:neighbor]}</a>" : oids[:neighbor]
      port = oids[:if_alias][/__[0-9a-zA-Z\-.: \/]+$/] || ''
      port.empty? || opts[:device_only] ? neighbor : "#{neighbor} (#{port.gsub('__','')})"
    else
      ''
    end
  end

  def interface_link(settings, oids)
    "<a href='#{settings['grafana_if_dash']}" +
      "?title=#{oids[:device]}%20::%20#{CGI::escape(oids[:if_name])}" +
    "&name=#{oids[:device]}.#{oids[:if_index]}" +
    "&ifSpeedBps=#{oids[:if_high_speed].to_i * 1000000 }" +
    "&ifMaxBps=#{[ oids[:bps_in].to_i, oids[:bps_out].to_i ].max}" + 
                   "' target='_blank'>" + oids[:if_name] + '</a>'
  end

  def device_link(oids)
    "<a href='/device/#{oids[:device]}'>#{oids[:device]}</a>"
  end

  def link_status_color(interfaces,oids)
    return 'grey' if oids[:stale]
    return 'red' unless oids[:link_up]
    return 'orange' if !oids[:discards_out].to_s.empty? && oids[:discards_out] != 0
    return 'orange' if !oids[:errors_in].to_s.empty? && oids[:errors_in] != 0
    # Check children -- return orange unless all children are up
    if oids[:is_parent]
      oids[:children].each do |child_index|
        return 'orange' unless interfaces[child_index][:link_up]
      end
    end
    return 'green'
  end

  def link_status_tooltip(interfaces,oids)
    discards = oids[:discards_out] || 0
    errors = oids[:errors_in] || 0
    stale_warn = oids[:stale] ? "Last polled: #{humanize_time(oids[:stale])} ago\n" : ''
    discard_warn = discards == 0 ? '' : "#{discards} outbound discards/sec\n"
    error_warn = errors == 0 ? '' : "#{errors} receive errors/sec\n"
    child_warn = ''
    if oids[:is_parent]
      oids[:children].each do |child_index|
        child_warn = "Child link down\n" unless interfaces[child_index][:link_up]
      end
    end
    state = oids[:link_up] ? 'Up' : 'Down'
    time = humanize_time(Time.now.to_i - oids[:if_oper_status_time])
    return stale_warn + discard_warn + error_warn + child_warn + "#{state} for #{time}"
  end

  def number_to_human(raw, unit, si=true, format='%.2f')
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
