#
# Pixel is an open source network monitoring system
# Copyright (C) 2016 all Pixel contributors!
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

charts = []
ajaxRefreshID = {}

ready = ->
  sort_table()
  set_hovers()
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

    url = '/v1/series/rickshaw?query=select%20*%20from%20' + attribute + '%20where%20device%3D%27' + device +
    '%27%20and%20time%20%3E%20now()%20-%20' + timeframe + '%20order%20by%20time%20desc&attribute=' + attribute

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


set_onclicks = (el) ->
  parent = if el? then el else $(':root')

  parent.find('thead > tr > th').unbind('click.pixel1')
  parent.find('thead > tr > th').on 'click.pixel1': ->
    set_focus()

  parent.find('.swapPlusMinus').unbind('click.pixel2')
  parent.find('.swapPlusMinus').on 'click.pixel2': ->
    $(this).find('span').toggleClass('glyphicon-plus glyphicon-minus')
    $(this).closest('tr').toggleClass('tr-expanded')
    $(this).closest('tr').nextUntil('tr:not(.tablesorter-childRow)').find('td:not(.pxl-hidden)').slideToggle(50)
    set_focus()

  parent.find('.pxl-btn-refresh').unbind('click.pixel3')
  parent.find('.pxl-btn-refresh').on 'click.pixel3': ->
    $(this).toggleClass('pxl-btn-refresh-white pxl-btn-refresh-green')
    if $.cookie('auto-refresh') && $.cookie('auto-refresh') != 'false'
      clearInterval($.cookie('auto-refresh'))
      $.cookie('auto-refresh', 'false', { expires: 365, path: '/' })
    else
      set_refresh()
    set_focus()

  parent.find('.pxl-set-focus').unbind('click.pixel4')
  parent.find('.pxl-set-focus').on 'click.pixel4': -> set_focus()

  parent.find('.pxl-text-swap').unbind('click.pixel5')
  parent.find('.pxl-text-swap').on 'click.pixel5': ->
    newText = $(this).data('text-swap')
    $(this).data('text-swap', $(this).text())
    $(this).text(newText)


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

set_hovers = (el) ->
  parent = if el? then el else $(':root')
  parent.find('.pxl-sort').hover ->
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
    { highlight: true },
    {
      name: 'devices',
      # `ttAdapter` wraps the suggestion engine in an adapter that
      # is compatible with the typeahead jQuery plugin
      source: devices.ttAdapter()
    },
  )
  $('.ig-typeahead').typeahead(
    { highlight: true },
    { name: 'devices', source: devices.ttAdapter() },
  )
  $('.input-group').find('span.twitter-typeahead').addClass('pxl-tt-ig')

  $('input.typeahead').bind("typeahead:selected", -> $("form").submit() )


d3_init = ->
  # Only continue if we have ajax tables or lists
  if $('.ajax_table').length != 0
    clearInterval($.cookie('auto-refresh'))
    $('.ajax_table').each ->
      table = $(this)
      id = table.attr('id')
      refresh_time = table.data('api-refresh')
      if refresh_time?
        ajaxRefreshID[id] = window.setInterval((-> d3_table_fetch(table)), refresh_time * 1000)
      d3_table_fetch(table)
  if $('.ajax_list').length != 0
    clearInterval($.cookie('auto-refresh'))
    $('.ajax_list').dynamicTree()


d3_table_fetch = (table) ->
    url = table.data('api-url')
    params = table.data('api-params').split(',').join('&')

    $.ajax "#{url}?#{params}",
      success: (data, status, xhr) ->
        data = $.parseJSON(data)
        meta = data['meta']
        meta ?= {}
        data = data['data']
        data = parse_event_data(data)
        d3_table_update(table, data, meta)
      error: (xhr, status, err) ->
      complete: (xhr, status) ->
        # trigger tablesorter update, and perform initial sort if
        # we previously had no data
        fresh_data = true if table[0].config.totalRows == 0
        # Default is to sort ascending, unless data-sort attribute is set to 'desc'
        sort = if table.data('sort')?.match('desc') then 0 else 1
        table.trigger('updateAll')
        table.trigger('sorton', [[[0,sort]]]) if fresh_data
        set_onclicks()
        color_table()
        tooltips()
        # The data is resetting the td to glyphicon-plus -- need to reset the expanded/collapsed state:
        # (this is specific to interfaces)
        $('.glyphicon-plus').closest('tr').nextUntil('tr:not(.tablesorter-childRow)').find('td').hide()
        $('.tr-expanded').each (s) ->
          $(this).find('.swapPlusMinus span').each (s) ->
            $(this).toggleClass('glyphicon-plus glyphicon-minus')
            $(this).closest('tr').nextUntil('tr:not(.tablesorter-childRow)').find('td').toggle()
            $(this).closest('tr').nextUntil('tr:not(.tablesorter-childRow)').find('.pxl-hidden').toggle()


d3_table_update = (jq_table, data, meta) ->

  number_of_cols = 0

  columns = $.map(jq_table.data('api-columns').split(','), (pair) ->
    split = pair.split(':')
    c = {}
    c[split[0]] = {
      name: split[1],
      colspan: split[2]
    }
    number_of_cols += 1 if split[2] > 0
    c
  )

  table_id = jq_table.attr('id')
  table = d3.select("##{table_id}")

  # If the column have changed (or didn't exist), we need to rebuild them from scratch
  # to avoid issues with hovering and sorting.  Also initialize the filters here!
  if jq_table.first('th').length == 0 || number_of_cols != jq_table.find('th').length
    table.select('thead').selectAll('th').remove() # kill all the existing <th>s
    thead = table.select('thead').select('tr').selectAll('th') # create new ones
      .data(columns.filter((d) ->
        column = d3.values(d)[0]
        column.colspan > 0
      ))
      .enter()
      .append('th')
      .text((column) -> d3.values(column)[0].name)
      .attr('colspan', (d,i) -> d3.values(d)[0].colspan)
      .classed('pxl-hidden', (d,i) -> d3.values(d)[0].name == '_hidden_')
      .classed('pxl-sort', (column_data) ->
        column = d3.keys(column_data)[0]
        (meta['_th_']? && meta['_th_']['pxl-sort']?)
      )
    # Add sort icons
    table.selectAll('.pxl-sort')
      .append('span')
      .attr('class', 'glyphicon glyphicon-sort pxl-sort-icon pxl-hidden')
    set_hovers(jq_table)
    set_onclicks(jq_table)

    # Get dropdown data
    $.each(meta['_dropdowns_'], (field, dd_data) ->
      url = dd_data['url']
      placeholder = dd_data['placeholder']
      dropdown_id = "##{table_id}_#{field}"
      $.ajax url,
        success: (data, status, xhr) ->
          data = $.parseJSON(data)
          d3.select(dropdown_id).selectAll('option')
            .data(data)
            .enter()
            .append('option')
            .text((d) -> d3.values(d)[0])
            .attr('value', (d) -> d3.keys(d)[0])
          $(dropdown_id).multiselect({
            buttonWidth: '100%',
            enableHTML: true,
            nonSelectedText: "<span class='pxl-placeholder'>#{placeholder}</span>",
            numberDisplayed: 2,
            dropRight: true,
            enableFiltering: true,
            enableCaseInsensitiveFiltering: true,
            onDropdownHide: (e) -> set_focus()
          })
          # When the clear button is clicked, unselect all the options
          $("#{dropdown_id}_reset").on click: ->
            select_id = $(this).attr('id').replace('_reset', '')
            $("##{select_id} option:selected").each( -> $(this).prop('selected', false))
            $("##{select_id}").multiselect('refresh')
            set_focus()
        error: (xhr, status, err) ->
        complete: (xhr, status) ->
    )

    params = $.each(jq_table.data('api-params').split(','), (i, pair) ->
      param = pair.split('=')[0]
      value = pair.split('=')[1]
      input = $("##{table_id}_#{param}")
      if(input.length > 0)
        input.val(value)
    )

    # Apply button should update api-params data and refresh the data
    $("##{table_id}_apply").unbind("click.pixel")
    $("##{table_id}_apply").on 'click.pixel': ->
      # Reset the refresh timer
      refresh_time = jq_table.data('api-refresh')
      window.clearInterval(ajaxRefreshID[table_id])
      ajaxRefreshID[table_id] = window.setInterval((-> d3_table_fetch(jq_table)), refresh_time * 1000) if refresh_time

      # apply params to the table & get new dataset
      params = []
      $.each(meta['_filters_'], (i, filter) ->
        element = $("##{table_id}_#{filter}")
        if element.is('select')
          value = element.find(':selected').map(-> this.value).get().join('$')
        else if element.is(':checkbox')
          value = if element.is(':checked') then 'true' else ''
        else if filter.match(/(start|end)_time/)
          value = element?.val()
          if value? && value.trim()
            value = value.replace(' @ ','T')
            s = value.split(/\D+/)
            value = ((new Date(s[0], --s[1], s[2], s[3], s[4], s[5]? || 0)).getTime() / 1000).toString()
        else
          value = element?.val()
        if (value? && value.trim()) then params.push("#{filter}=#{value}")
      )
      jq_table.data('api-params', params.join(','))
      d3_table_fetch(jq_table)

  tbody = table.select('tbody')

  # Helper functions for data binding

  ident = (d) ->
    if ('object'.match typeof d)
      return d['data']
    return d

  get_keys = (d) ->
    d[table.attr('data-api-key')]

  get_cell_data = (d) ->
    columns.map((column) ->
      d[d3.keys(column)[0]]) # Here 'column' looks like {'time': 'Time '}

  tr = tbody.selectAll("tr.dynamic")
    .data(data, get_keys)
  tr.enter().append("tr")
    .attr('class', 'dynamic') # So we can separate this TR from any child TRs
    .classed('tablesorter-childRow pxl-child-tr', (d,i) -> d.child)
    .style('opacity', 0)
    .transition().duration(500)
    .style('opacity', 1)
  tr.exit()
    .classed('remove-me', true) # For tablesorter compatibility
    .transition().duration(300)
    .style('opacity', 0)
    .remove()

  td = tr.selectAll("td.dynamic")
    .data(get_cell_data)
  td.enter()
    .append("td")
    .attr('class', 'dynamic') # So we can separate this TR from any child TRs
    # Apply attrs and class if the cell data is a hash and has the attribute/class key
    .attr('data-pxl-meta', (d,i) -> d && d['pxl-meta'])
    .classed('pxl-meta', (d,i) -> d && d['pxl-meta'])
    .classed('pxl-td-shrink', (d,i) -> d && d['pxl-td-shrink'])
    .classed('pxl-histogram', (d,i) -> d && d['pxl-histogram'])
    .classed('pxl-hidden', (d,i) -> d && d['pxl-hidden'])

  td.html(ident)


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
