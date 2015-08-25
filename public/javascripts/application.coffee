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


set_onclicks = (el) ->
  parent = if el? then el else $(':root')

  parent.find('thead > tr > th').on click: ->
    set_focus()
  parent.find('.swapPlusMinus').on click: ->
    $(this).find('span').toggleClass('glyphicon-plus glyphicon-minus')
    set_focus()
  parent.find('.pxl-btn-refresh').on click: ->
    $(this).toggleClass('pxl-btn-refresh-white pxl-btn-refresh-green')
    if $.cookie('auto-refresh') && $.cookie('auto-refresh') != 'false'
      clearInterval($.cookie('auto-refresh'))
      $.cookie('auto-refresh', 'false', { expires: 365, path: '/' })
    else
      set_refresh()
    set_focus()
  parent.find('.pxl-set-focus').on click: -> set_focus()
  parent.find('.pxl-text-swap').on click: ->
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

  # This is run on each sort to separate the child parent relationship somewhat
  $('table').bind 'sortStart', ->
    $('.pxl-child-tr').removeClass('pxl-child-tr')
    $('tbody tr td span.pxl-hidden').removeClass('pxl-hidden')
    set_hoverswaps()
  # Show the th sort arrows when hovering

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
    $('.ajax_list').each ->
      list = $(this)
      id = list.attr('id')
      refresh_time = list.data('api-refresh')
      if refresh_time?
        ajaxRefreshID[id] = window.setInterval((-> d3_list_fetch(list)), refresh_time * 1000)
      d3_list_fetch(list)


d3_list_fetch = (list) ->
    $.ajax list.data('api-url'),
      success: (data, status, xhr) ->
        data = $.parseJSON(data)
        d3_list_update(list, data)

      error: (xhr, status, err) ->
      complete: (xhr, status) ->


d3_list_update = (jq_list, data) ->
  list_id = jq_list.attr('id')
  list = d3.select("##{list_id}")

  # Set up Configuration section
  dropdown_id = "##{list_id}_dd"
  selector_list = d3.select(dropdown_id).selectAll('li')
    # The next line filters out _list_display_ from the keys
    .data( $.grep(d3.keys(data[0]), (v) -> !v.match('_list_display_')) )
  selector_list.enter()
    .append('li')
    .classed('pxl-list-dd-option', true)
    .html((d) -> "<a href='#'>#{d}</a>")
  selector_list.exit().remove()

  selectors = $.parseJSON(decodeURIComponent($.url("?#{list_id}_selectors")))
  selectors ?= [] # Set it to empty if we didn't get anything from the URL

  add_selector = (selector, container) ->
    selector_text = d3.keys(selector)[0]
    regex = selector[selector_text]
    newLayer = $("
    <div id=\"#{selector_text}_id\" data-selector=\"#{selector_text}\"
    class=\"input-group pxl-bottom-5 #{list_id}_layer\">
      <span class=\"input-group-addon\">#{selector_text}</span>
      <span class=\"input-group-addon\">
        <label style='margin-bottom: 0px;'>
          <input type=\"checkbox\" class=\" pxl-checkbox\" />&nbsp;Regex</input>
        </label>
      </span>
      <input type=\"text\" class=\"#{list_id}_input form-control\"
        placeholder=\"Don't include leading and trailing slashes\" disabled />
      <span class=\"input-group-btn\">
        <button class=\"btn btn-default\">
          <span class=\"glyphicon glyphicon-remove\"></span>
        </button>
      </span>
    </div>
    ")
    # Load the regex if we were passed one -- this is for saved links
    if regex
      newLayer.find('label input').prop('checked', true)
      newLayer.find(".#{list_id}_input").prop('disabled', (i, v) -> !v)
      newLayer.find(".#{list_id}_input").val(regex)
    newLayer.hide().appendTo(container).show('slow')
    newLayer.find('label input').first().on click: ->
      newLayer.find(".#{list_id}_input").prop('disabled', (i, v) -> !v)
      newLayer.find(".#{list_id}_input").val(null)
      apply_layers(list_id, data)
      set_focus()
    newLayer.find(".#{list_id}_input").focusout( -> apply_layers(list_id, data) )
    newLayer.find('span button').first().on click: ->
      $(newLayer).hide('slow', ->
        $(this).remove()
        apply_layers(list_id, data)
      )
    apply_layers(list_id, data)

  container = $("##{list_id}_layers")

  $('.pxl-list-dd-option').each( ->
    $(this).find('a').on click: ->
      selector = {}
      selector[$(this).text()] = null
      add_selector(selector, container)
  )

  $.each(selectors, (k, selector) ->
    add_selector(selector, container)
  )

  apply_layers(list_id, data)

update_list_link = (list_id, selectors) ->
  a = $("##{list_id}_link")
  a.attr('href', "?#{list_id}_selectors=#{encodeURIComponent(JSON.stringify(selectors))}")

apply_layers = (list_id, data) ->
  jq_list = $("##{list_id}")
  list = d3.select("##{list_id}")
  selectors = []
  $(".#{list_id}_layer").each( ->
    hash = {}
    key = $(this).data('selector')
    value = $(this).find(".#{list_id}_input").val()
    hash[key] = value
    selectors.push(hash)
  )

  update_list_link(list_id, selectors)

  display = '_list_display_'

  new_data = { txt: 'root', children: [] }
  # This function is used recursively to generate a custom tree of devices,
  # which is later used to generate a D3 structure
  generate_data = (nodes, index) ->
    selector = selectors[index]
    # If there are no more selectors to process, just list the devices
    if selector == undefined
      return $.map(nodes, (node, k) -> { txt: node[display], children: [] } )
    selector_field = d3.keys(selector)[0]
    selector_regex = d3.values(selector)[0]
    tree = []
    categories = {}
    $.each(nodes, (k, node) ->
      instance = node[selector_field] # vendor / device/ sw_descr etc
      # REGEXP
      if selector_regex
        match = RegExp(selector_regex).exec(instance)
        category = if match then match[1] else '(unmatched)'
        category = match[0] if category == undefined
      else
        category = instance
        category ?= '(unmatched)'
      categories[category] ?= []
      categories[category].push(node)
    )
    $.each(categories, (category, children) ->
      tree.push {
        txt: category,
        children: generate_data(children, index + 1),
        count: children.length
      }
    )
    return tree

  new_data['children'] = generate_data(data, 0)

  generate_list = (parent_lists) ->
    item = parent_lists.selectAll('ul')
      .data((d) ->
        # If there are no children, don't generate a new list
        if $.isEmptyObject(d.children) then [] else [d]
      )
      .enter().append('ul')
      .classed('list-group', true)
      .attr('data-new-item', true)
    children = item.selectAll('li')
      .data((d) ->
        # Sort the data alphabetically, and ensure (unmatched) is always at the end
        d.children.sort((a, b) ->
          if a.txt.match('(unmatched)') then return 1
          if b.txt.match('(unmatched)') then return -1
          d3.ascending(a.txt, b.txt)
        )
      )
      .enter().append('li')
      .html((d) ->
        if d.count > 0 then "#{d.txt} <span class='badge'>#{d.count}</span>" else d.txt
      )
      .classed('list-group-item', true)
      .classed('list-group-link', (d) -> $.isEmptyObject(d.children))
    # Recurse if we have more layers to work through
    if !(children.empty())
      generate_list(children)

  # Clear out the old data first
  jq_list.empty()

  # Generate a new list
  root_list = list.selectAll('div').data([new_data]).enter().append('div')
  generate_list(root_list)

  # el should be a ul
  set_toggles = (el) ->
    if !el.data('new-item') then return
    if el.length == 0 then return
    el.children('li').on click: (event) ->
      $(this).children('ul').toggle(200)
      event.stopPropagation()
    # Set the hover classes. This is retarded why can't CSS do this
    el.children('li').mouseover((event) ->
      $(this).addClass('hover')
      event.stopPropagation()
    )
    el.children('li').mouseout((event) -> $(this).removeClass('hover'))
    el.children('li').children('ul').hide()
    # Remove the new tag
    el.removeData('new-item')
    set_toggles($(this).children('li').children('ul'))

  set_toggles(jq_list.find('div ul'))


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


d3_table_update = (jq_table, data, meta) ->

  columns = $.map(jq_table.data('api-columns').split(','), (pair) ->
    split = pair.split(':')
    c = {}
    c[split[0]] = split[1]
    c
  )

  ident = (d) ->
    if ('object'.match typeof d)
      return d['data']
    return d

  table_id = jq_table.attr('id')
  table = d3.select("##{table_id}")

  # If the column have changed (or didn't exist), we need to rebuild them from scratch
  # to avoid issues with hovering and sorting.  Also initialize the filters here!
  if jq_table.first('th').length == 0 || columns.length != jq_table.find('th').length
    table.select('thead').selectAll('th').remove() # kill all the existing <th>s
    thead = table.select('thead').select('tr').selectAll('th') # create new ones
      .data(columns)
      .enter()
      .append('th')
      .text((column) -> d3.values(column)[0]) # Here 'column' looks like {'time': 'Time '}
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
    $("##{table_id}_apply").on click: ->
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

  get_keys = (d) ->
    d[table.attr('data-api-key')]

  get_cell_data = (d) ->
    columns.map((column) ->
      d[d3.keys(column)[0]]) # Here 'column' looks like {'time': 'Time '}

  tr = tbody.selectAll("tr")
    .data(data, get_keys)
  tr.enter().append("tr")
    .style('opacity', 0)
    .transition().duration(500)
    .style('opacity', 1)
  tr.exit()
    .classed('remove-me', true) # For tablesorter compatibility
    .transition().duration(300)
    .style('opacity', 0)
    .remove()

  td = tr.selectAll("td")
    .data(get_cell_data)
    .enter()
    .append("td")
    # Apply attr and class if the cell data is a hash and has pxl-meta key
    .attr('data-pxl-meta', (d,i) -> d && d['pxl-meta'])
    .classed('pxl-meta', (d,i) -> d && d['pxl-meta'])
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
