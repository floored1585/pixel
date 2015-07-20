charts = []

ready = ->
  sort_table()
  set_th_hovers()
  color_table()
  set_onscrolls()
  tooltips()
  parent_child()
  set_onclicks()
  check_refresh()
  set_hoverswaps()
  draw_charts()
  typeahead()
  set_focus()
  d3_init()
  $(window).resize(check_charts)


set_onscrolls = ->
  $(window).scroll( ->
    if $(this).scrollTop() > 0
      if $('.pxl-fadescroll').css('margin-top') == '0px'
        $('.pxl-fadescroll').stop().animate({marginTop: '-2em'})
      #$('.pxl-fadescroll').fadeOut()
    else
      $('.pxl-fadescroll').stop().animate({marginTop: '0px'}, 'fast')
      #$('.pxl-fadescroll').fadeIn()
  )
  $('.pxl-fadescroll').hover \
    (-> $(this).filter(':not(:animated)').animate({marginTop: '0px' })), \
    (->
      if $(window).scrollTop() > 0 # prevent hiding when @ top of page
        $(this).filter(':not(:animated)').animate({marginTop: '-2em' }))


draw_charts = ->
  $('.pxl-rickshaw').each ->
    element = $(this)
    device = element.data('pxl-device')
    attribute = element.data('pxl-attr')
    timeframe = element.data('pxl-time')

    # 'next' unless all the variables are defined and not empty
    return true if (!device || !attribute || !timeframe)

    url = '/v1/series/rickshaw?query=select%20*%20from%20%2F' + device + '.' + attribute +
    '%2F%20where%20time%20>%20now()%20-%20' + timeframe + '&attribute=' + attribute

    generate_charts(element, url)


check_charts = ->
  need_to_update = true
  if need_to_update
    for chart, i in charts
      chart['graph'].setSize()
      chart['graph'].render()
      chart['axes']['x'].render()
      chart['axes']['y'].render()


generate_charts = (element, url) ->
  element_y = element.parent().find('.pxl-rickshaw-y')[0]
  graph = new Rickshaw.Graph.Ajax({
    element: element[0],
    min: 0,
    max: 100 + element.height() / 20
    renderer: 'line',
    dataURL: url,
    onComplete: (transport) ->
      graph = transport.graph
      graph.render()
      detail = new Rickshaw.Graph.HoverDetail({
        graph: graph,
        formatter: (series, x, y) ->
          date = 'Time: <span class="date">' + moment(x * 1000).format('HH:mm') + '</span>'
          value = 'Value: <span class="value">' + parseInt(y) + '%</span>'
          content = series.name + '<br>' + date + '&nbsp;&nbsp;&nbsp;' + value
      })
      axes = {
        x: new Rickshaw.Graph.Axis.Time({
          graph: graph,
          timeFixture: new Rickshaw.Fixtures.Time.Local()
        }),
        y: new Rickshaw.Graph.Axis.Y({ graph: graph, element: element_y })
      }
      charts.push({ graph: graph, axes: axes })
      axes['x'].render()
      axes['y'].render()
  })


toReadable = (raw,unit,si) ->
  i = 0
  units = {
    bps: [' bps', ' Kbps', ' Mbps', ' Gbps', ' Tbps', ' Pbps', ' Ebps', ' Zbps', ' Ybps']
    pps: [' pps', ' Kpps', ' Mpps', ' Gpps', ' Tpps', ' Ppps', ' Epps', ' Zpps', ' Ypps']
  }
  step = if si then 1000 else 1024
  while (raw > step)
    raw = raw / step
    i++
  return raw.toFixed(2) + units[unit][i]


check_refresh = ->
  if $.cookie('auto-refresh') != 'false'
    $('.pxl-btn-refresh').toggleClass('pxl-btn-refresh-white pxl-btn-refresh-green')
    set_refresh()


refresh_page = -> location.reload()


set_refresh = ->
  siid = setInterval refresh_page, 120000
  $.cookie('auto-refresh', siid, { expires: 365, path: '/' })


set_focus = -> $('#device_input').focus()


set_onclicks = ->
  $('#event-refresh').on click: ->
    d3_fetch()
  $('table > thead > tr > th').on click: ->
    set_focus()
  $('.swapPlusMinus').on click: ->
    $(this).find('span').toggleClass('glyphicon-plus glyphicon-minus')
    set_focus()
  $('.pxl-btn-refresh').on click: ->
    $(this).toggleClass('pxl-btn-refresh-white pxl-btn-refresh-green')
    if $.cookie('auto-refresh') && $.cookie('auto-refresh') != 'false'
      clearInterval($.cookie('auto-refresh'))
      $.cookie('auto-refresh', 'false', { expires: 365, path: '/' })
    else
      set_refresh()
    set_focus()


tooltips = ->
  $('[data-rel="tooltip-left"]').tooltip({ placement: 'left', animation: false })
  $('[data-rel="tooltip-right"]').tooltip({ placement: 'right', animation: false })
  $('[data-rel="tooltip-bottom"]').tooltip({ placement: 'bottom', animation: false })


parent_child = ->
  $('tr[class*=child]').mouseenter -> hl_parent($(this),'#E5E5E5')
  $('tr[class*=child]').mouseleave -> hl_parent($(this),'#FFF')


hl_parent = (child,color) ->
  parent = $(child).data('pxl-parent')
  parent_row = $("tr[data-pxl-index='"+parent+"']")
  parent_row.css('background-color',color)
  for cell in parent_row.find('.pxl-histogram')
    color_cell(cell,color)


sort_table = ->
  # Function for sorting on metadata
  pxl_meta = (node) ->
    if($(node).hasClass('pxl-meta'))
      $(node).data('pxl-meta')
    else
      node.innerText

  # Initialize tablesorter
  $('.tablesorter').tablesorter({
    sortList: [[0,1]],
    sortInitialOrder: 'desc'
    textExtraction: pxl_meta
  })
  $('.d3-tablesorter').tablesorter({
    sortList: [[0,1]],
    resort: true,
    textExtraction: pxl_meta
  })

  # This is run on each sort to separate the child parent relationship somewhat
  $('table').bind 'sortStart', ->
    $('.pxl-child-tr').removeClass('pxl-child-tr')
    $('tbody tr td span.pxl-hidden').removeClass('pxl-hidden')
    set_hoverswaps()
  # Show the th sort arrows when hovering

set_th_hovers = ->
  $('.pxl-th').hover ->
    $(this).find('span').toggleClass('pxl-hidden')


color_cell = (cell,bgcolor) ->
  return if !cell.firstChild # Exits if the cell is empty
  percentage = $(cell).data('pxl-meta')
  if percentage < 80
    color = '#BFB'
  else if percentage < 90
    color = '#FFB'
  else
    color = '#FBB'
  if percentage > 0
    cell.style.background="-webkit-gradient(linear, left top,right top, color-stop(#{percentage}%,#{color}), color-stop(#{percentage}%,#{bgcolor}))"
    cell.style.background="-moz-linear-gradient(left center,#{color} #{percentage}%, #{bgcolor} #{percentage}%)"
    cell.style.background="-o-linear-gradient(left,#{color} #{percentage}%, #{bgcolor} #{percentage}%)"
    cell.style.background="linear-gradient(to right,#{color} #{percentage}%, #{bgcolor} #{percentage}%)"


color_table = ->
  $('tr').mouseenter ->
    for cell in $(this).find('.pxl-histogram')
      color_cell(cell,'#F5F5F5')
  $('tr').mouseleave ->
    for cell in $(this).find('.pxl-histogram')
      color_cell(cell,'#FFF')
  bgcolor = '#FFF'
  for cell in document.getElementsByClassName('pxl-histogram')
    color_cell(cell,bgcolor)


set_hoverswaps = ->
  $('td span.pxl-swap-alt').addClass('pxl-hidden')
  $('tr td.pxl-hoverswap').hover ->
    $(this).find("[class^='pxl-swap']").toggleClass('pxl-hidden')


typeahead = ->
  devices = new Bloodhound({
    datumTokenizer: (d) ->
      test = Bloodhound.tokenizers.whitespace(d.value)
      $.each(test, (k,v) ->
        i = 0
        while( (i+1) < v.length )
          test.push(v.substr(i,v.length))
          i++
      )
      return test
    ,
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    limit: 10,
    prefetch: {
      url: '/v2/devices',
      filter: (list) ->
        $.map(list, (device) -> { value: device })
        # the json file contains an array of strings, but the Bloodhound
        # suggestion engine expects JavaScript objects so this converts all of
        # those strings
    }
  })

  # kicks off the loading/processing of `local` and `prefetch`
  devices.clearPrefetchCache()
  devices.initialize()


  # passing in `null` for the `options` arguments will result in the default
  # options being used
  $('.typeahead').typeahead(
    {
      highlight: true,
    },
    {
      name: 'devices',
      # `ttAdapter` wraps the suggestion engine in an adapter that
      # is compatible with the typeahead jQuery plugin
      source: devices.ttAdapter()
    },
  )
  $('input.typeahead').bind("typeahead:selected", -> $("form").submit() )

d3_init = ->
  window.setInterval((-> d3_fetch()), 5000)
  d3_fetch()

d3_fetch = ->
  $('.ajax_table').each ->
    table = $(this)
    url = table.data('api-url')
    params = table.data('api-params').split(',').join('&')

    id = table.attr('id')

    $.ajax "#{url}?#{params}&ajax=true",
      success: (data, status, xhr) ->
        data = parse_event_data($.parseJSON(data))
        d3_update(table, data)
      error: (xhr, status, err) ->
      complete: (xhr, status) ->
        # trigger tablesorter update, and perform initial sort if
        # we previously had no data
        fresh_data = true if table[0].config.totalRows == 0
        table.trigger('updateAll')
        table.trigger('sorton', [[[0,1]]]) if fresh_data


d3_update = (jq_table, data) ->

  columns = $.map(jq_table.data('api-columns').split(','), (pair) ->
    split = pair.split(':')
    c = {}
    c[split[0]] = split[1]
    c
  )

  ident = (d) -> d

  table = d3.select("##{jq_table.attr('id')}")

  # If the column have changed (or didn't exist), we need to rebuild them from scratch
  # to avoid issues with hovering and sorting
  if jq_table.first('th').length == 0 || columns.length != jq_table.find('th').length
    th_html = "<span class='glyphicon glyphicon-sort pxl-sort-icon pxl-hidden'></span>"
    th_html += "<span class='glyphicon glyphicon-filter pxl-filter-icon'></span>"
    table.select('thead').selectAll('th').remove() # kill all the existing <th>s
    thead = table.select('thead').select('tr').selectAll('th') # create new ones
      .data(columns)
      .enter()
      .append('th')
      .text((column) -> d3.values(column)[0]) # Here 'column' looks like {'time': 'Time '}
      .attr('class', 'pxl-th')
    thead.append('span').attr('class', 'glyphicon glyphicon-sort pxl-sort-icon pxl-hidden')
    #thead.append('span').attr('class', 'glyphicon glyphicon-filter pxl-filter-icon pxl-hidden')
    set_th_hovers()

  tbody = table.select('tbody')

  # Helper functions for data binding

  get_keys = (d) ->
    d[table.attr('data-api-key')]

  get_cell_data = (d) ->
    columns.map((column) ->
      d[d3.keys(column)[0]]) # Here 'column' looks like {'time': 'Time '}

  tr = tbody.selectAll("tr")
    .data(data, get_keys)
  tr.enter().append("tr")
  tr.exit().remove()

  td = tr.selectAll("td")
    .data(get_cell_data)
    .enter()
    .append("td")
    .html(ident)


parse_event_data = (data) ->
  $.map(data, (obj) ->
    date_format = 'yyyy-MM-dd @ HH:mm'
    obj['time'] = epoch_to_local(obj['time'], date_format) if obj['time'] != undefined
    return obj
  )


epoch_to_local = (epoch, format) -> $.format.date(new Date(epoch * 1000), format)


# This function eliminates the Class information and parses JSON from the Pixel API
unwrap_ruby_json = (json) ->
  new_data = []
  $.each(data, (k,v) ->
    new_data.push(v['data'])
  )
  return new_data


$(document).ready(ready)
$(document).on('page:load', ready)
