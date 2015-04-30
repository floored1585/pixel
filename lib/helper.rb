module Helper


  def humanize_time seconds
    [[60, :seconds], [60, :minutes], [24, :hours], [1000000, :days]].map{ |count, name|
      if seconds > 0
        seconds, n = seconds.divmod(count)
        if n.to_i > 1
          "#{n.to_i} #{name}"
        else
          "#{n.to_i} #{name.to_s.gsub(/s$/,'')}"
        end
      else
        return '0 seconds' if name == :seconds
      end
    }.compact[-1]
  end


  def full_title(page_title)
    base_title = "Pixel"
    if page_title.nil? || page_title.empty?
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

    traffic = number_to_human(bps, units: units, sigfigs: sigfigs)
    return traffic if bps_only
    return util if pct_only
    return "#{util} (#{traffic})"
  end


  def total_bps_cell(int, parent)
    # If interface is child, set total to just under parent total,
    # so that the interface is sorted to sit directly under parent
    # when tablesorter runs.
    total = int.bps_in + int.bps_out
    if parent.class == Interface
      parent_total = parent.bps_in + parent.bps_out
      offset = total / (int.speed.to_f) * 10
      return parent_total - 20 + offset
    end
    # If not child, just return the total bps
    return total
  end


  def speed_cell(int)
    return '' if int.down?
    number_to_human(int.speed, units: :bps, sigfigs: 2)
  end


  def neighbor_link(int, opts={})
    if int.neighbor
      neighbor = "<a href='/device/#{int.neighbor}'>#{int.neighbor}</a>"
      port = int.neighbor_port || ''
      port.empty? || opts[:device_only] ? neighbor : "#{neighbor} (#{port})"
    elsif int.type == 'unknown'
      int.description || ''
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
    "&name=#{int.device}.interface.#{int.index}.#{int.name}" +
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


  def link_status_color(int, children=[])
    # hardcoded 10m -- TODO: Change to config value
    return 'grey' if int.stale?
    return 'darkRed' if int.status(:admin) == 'Down'
    return 'red' if int.down?
    return 'orange' if int.discards_in > 0 || int.discards_out > 0
    return 'orange' if int.errors_in > 0 || int.errors_out > 0
    # Check children -- return orange if any children are down
    children.each do |child|
      return 'orange' if child.down?
    end
    return 'green'
  end


  def link_status_tooltip(int, children)
    tooltip = ''
    tooltip << "Shutdown\n" if int.status(:admin) == 'Down'
    tooltip << "Last polled: #{humanize_time(int.stale?)} ago\n" if int.stale?
    tooltip << "#{int.discards_in} inbound discards/sec\n" if int.discards_in > 0
    tooltip << "#{int.discards_out} outbound discards/sec\n" if int.discards_out > 0
    tooltip << "#{int.errors_out} inbound errors/sec\n" if int.errors_in > 0
    tooltip << "#{int.errors_out} outbound errors/sec\n" if int.errors_out > 0
    children.each do |child|
      tooltip << "Child link down\n" if child.down?
    end
    time = humanize_time(Time.now.to_i - int.oper_status_time)
    return "#{tooltip}#{int.status} for #{time}"
  end


  def sw_tooltip(device)
    if device.vendor && device.sw_descr && device.sw_version
      "running #{device.sw_descr} #{device.sw_version}"
    else
      "No software data found"
    end
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
    oid = oid.to_sym
    oids_to_modify = [
      :bps_out, :pps_out, :discards_out, :errors_out,  :uptime,
      :last_poll_duration, :last_poll, :next_poll, :currently_polling, :last_poll_result,
      :yellow_alarm, :red_alarm
    ]
    pps_oids = [ :discards_out, :errors_out, :pps_out ]
    # abort on empty or non-existant values
    return value unless value && !value.to_s.empty?
    return value unless oids_to_modify.include?(oid)

    output = "#{value} (" if opts[:add]

    output << number_to_human(value, units: :bps) if oid == :bps_out
    output << number_to_human(value, units: :pps) if pps_oids.include?(oid)
    output << humanize_time(value) if [ :uptime, :last_poll_duration ].include?(oid)
    output << epoch_to_date(value) if [ :last_poll, :next_poll ].include?(oid)
    output << (value == 1 ? 'Yes' : 'No') if oid == :currently_polling
    output << (value == 1 ? 'Failure' : 'Success') if oid == :last_poll_result
    output << (value == 2 ? 'Inactive' : 'Active') if [ :yellow_alarm, :red_alarm ].include?(oid)

    output << ")" if opts[:add]
    return output
  end

end
