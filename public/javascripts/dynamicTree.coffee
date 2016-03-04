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

# This plugin is a travesty of the highest degree, some of the worst
# code I've ever written.

# Reference jQuery
$ = jQuery

# Adds plugin object to jQuery
$.fn.extend
  # Change pluginName to your plugin's name.
  dynamicTree: (options) ->
    # Default settings
    settings =
      option1: true
      option2: false
      debug: false

    # Merge default settings with options.
    settings = $.extend settings, options

    # Simple logger.
    log = (msg) ->
      console?.log msg if settings.debug

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
    
      # Update the link for this tree
      $("##{list_id}_link").attr('href', "?#{list_id}_selectors=#{encodeURIComponent(JSON.stringify(selectors))}")
    
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
            category = '(unmatched)' if category == ''
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

    # _Insert magic here._
    return @each ()->
      list = $(this)
      id = list.attr('id')

      refresh_time = list.data('api-refresh')
      if refresh_time?
        ajaxRefreshID[id] = window.setInterval((-> d3_list_fetch(list)), refresh_time * 1000)

      $.ajax list.data('api-url'),
        success: (data, status, xhr) ->
          data = $.parseJSON(data)
          d3_list_update(list, data)
        error: (xhr, status, err) ->
        complete: (xhr, status) ->
