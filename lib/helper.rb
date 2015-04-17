module Helper


  def humanize_time secs
    [[60, :seconds], [60, :minutes], [24, :hours], [10000, :days]].map{ |count, name|
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


  def tr_attributes(int, parent=nil, hl_relation: false, hide_if_child: false)
    classes = []
    attributes = [
      "data-toggle='tooltip'",
      "data-container='body'",
      "title='index: #{int.index}'",
      "data-rel='tooltip-left'",
      "data-pxl-index='#{int.index}'",
    ]

    if parent && (hl_relation || hide_if_child)
      if parent.class == Interface
        attributes.push "data-pxl-parent='#{parent.index}'" if hl_relation
        classes.push("#{parent.index}_child") if hl_relation
        classes.push('panel-collapse collapse out') if hide_if_child
        classes.push('pxl-child-tr') if hl_relation
      else
        $LOG.error("HELPER: Non-existent parent '#{int.parent_name}' on #{int.device}. Child: #{int.name}")
      end
    end

    attributes.join(' ') + " class='#{classes.join(' ')}'"
  end


  def bps_cell(direction, int, sigfigs: 3, bps_only: false, pct_only: false, units: :bps)
    # If bps_in/Out doesn't exist, return blank
    return '' unless int.up?

    if direction == :in
      bps = int.bps_in
      bps_util = int.bps_util_in
    elsif direction == :out
      bps = int.bps_out
      bps_util = int.bps_util_out
    else
      return 'error'
    end

    util = "#{bps_util.sigfig(sigfigs)}%"

    traffic = number_to_human(bps, units: units, sigfigs: 2)
    return traffic if bps_only
    return util if pct_only
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


  def neighbor_link(int, opts={})
    if int.neighbor
      neighbor = "<a href='/device/#{int.neighbor}'>#{int.neighbor}</a>"
      port = int.neighbor_port || ''
      port.empty? || opts[:device_only] ? neighbor : "#{neighbor} (#{port})"
    elsif int.type == 'unknown'
      int.alias || ''
    else
      ''
    end
  end


  def device_link_graph(settings, device, text)
    "<a href='#{settings['grafana_dev_dash']}?device=#{device}" +
    "' target='_blank'>#{text}</a>"
  end


  def interface_link(settings, int)
    "<a href='#{settings['grafana_if_dash']}" +
    "?title=#{int.device}%20::%20#{CGI::escape(int.name)}" +
    "&name=#{int.device}.#{int.index}" +
    "&ifSpeedBps=#{int.speed}" +
    "&ifMaxBps=#{[ int.bps_in, int.bps_out ].max}" +
    "' target='_blank'>#{int.name}</a>"
  end


  def alarm_type_text(device)
    text = ''
    text << "<span class='text-danger'>RED</span> " if device.red_alarm
    text << "and " if device.red_alarm && device.yellow_alarm
    text << "<span class='text-warning'>YELLOW</span>" if device.yellow_alarm
    return text
  end


  def device_link(name)
    "<a href='/device/#{name}'>#{name}</a>"
  end


  def link_status_color(interfaces,oids)
    return 'grey' if oids[:stale]
    return 'darkRed' if oids[:if_admin_status] == 2
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
    shutdown = oids[:if_admin_status] == 2 ? "Shutdown\n" : ''
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
    return shutdown + stale_warn + discard_warn + error_warn + child_warn + "#{state} for #{time}"
  end


  def sw_tooltip(data)
    if data[:vendor] && data[:sw_descr] && data[:sw_version]
      "running #{data[:sw_descr]} #{data[:sw_version]}"
    else
      "No software data found"
    end
  end


  def count_children(devices, type=[:all])

    count = 0

    devices.each do |dev,data|
      count += 1 if ( type.include?(:devicedata) || type.include?(:all) ) && data[:devicedata]
      count += (data[:cpus] || {}).count if type.include?(:cpus) || type.include?(:all)
      count += (data[:fans] || {}).count if type.include?(:fans) || type.include?(:all)
      count += (data[:psus] || {}).count if type.include?(:psus) || type.include?(:all)
      count += (data[:memory] || {}).count if type.include?(:memory) || type.include?(:all)
      count += (data[:interfaces] || {}).count if type.include?(:interfaces) || type.include?(:all)
      count += (data[:temperatures] || {}).count if type.include?(:temperatures) || type.include?(:all)
    end

    return count
  end


  def number_to_human(raw, units:, si: true, sigfigs: 3)
    i = 0
    unit_list = {
      :bps => [' bps', ' Kbps', ' Mbps', ' Gbps', ' Tbps', ' Pbps', ' Ebps', ' Zbps', ' Ybps'],
      :pps => [' pps', ' Kpps', ' Mpps', ' Gpps', ' Tpps', ' Ppps', ' Epps', ' Zpps', ' Ypps'],
      :si_short => [' b', ' K', ' M', ' G', ' T', ' P', ' E', ' Z', ' Y'],
    }
    step = si ? 1000 : 1024
    while raw >= step do
      raw = raw.to_f / step
      i += 1
    end

    return "#{raw.sigfig(sigfigs)} #{unit_list[units][i]}"
    # ^-- Example: "234 Mbps"
  end


  def epoch_to_date(value, format='%-d %B %Y, %H:%M:%S UTC')
    DateTime.strptime(value.to_s, '%s').strftime(format)
  end


  def devicedata_to_human(oid, value, opts={})
    oids_to_modify = [ :bps_out, :pps_out, :discards_out, :uptime, :last_poll_duration,
                       :last_poll, :next_poll, :currently_polling, :last_poll_result,
                       :yellow_alarm, :red_alarm ]
    # abort on empty or non-existant values
    return value unless value && !value.to_s.empty?
    return value unless oids_to_modify.include?(oid)

    output = "#{value} (" if opts[:add]

    output << number_to_human(value, :bps) if oid == :bps_out
    output << number_to_human(value, :pps) if [ :pps_out, :discards_out ].include?(oid)
    output << humanize_time(value) if [ :uptime, :last_poll_duration ].include?(oid)
    output << epoch_to_date(value) if [ :last_poll, :next_poll ].include?(oid)
    output << (value == 1 ? 'Yes' : 'No') if oid == :currently_polling
    output << (value == 1 ? 'Failure' : 'Success') if oid == :last_poll_result
    output << (value == 2 ? 'Inactive' : 'Active') if [ :yellow_alarm, :red_alarm ].include?(oid)

    output << ")" if opts[:add]
    return output
  end

end
