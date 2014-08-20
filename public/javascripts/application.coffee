
ready = ->
  sort_table()
  color_table()
  tooltips()
  parent_child()
  set_focus()
  set_onclicks()
  check_refresh()
  set_hoverswaps()

toReadable = (raw,unit,si) ->
  i = 0
  units = {
    bps: [' bps', ' Kbps', ' Mbps', ' Gbps', ' Tbps', 'Pbps', 'Ebps', 'Zbps', 'Ybps']
    pps: [' pps', ' Kpps', ' Mpps', ' Gpps', ' Tpps', 'Ppps', 'Epps', 'Zpps', 'Ypps']
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
  # Initialize tablesorter
  $('.tablesorter').tablesorter({
    sortList: [[0,1]],
    sortInitialOrder: 'desc'
    textExtraction: (node) ->
      if($(node).hasClass('pxl-meta'))
        $(node).data('pxl-meta')
      else
        node.innerText
  })
  # This is run on each sort to separate the child parent relationship somewhat
  $('table').bind 'sortStart', ->
    $('.pxl-child-tr').removeClass('pxl-child-tr')
    $('tbody tr td span.pxl-hidden').removeClass('pxl-hidden')
  # Show the th sort arrows when hovering
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

$(document).ready(ready)
$(document).on('page:load', ready)
