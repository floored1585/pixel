require 'sinatra'
require 'yaml'
require 'sinatra/reloader'
require 'pg'

require_relative 'lib/core_ext/string.rb'

set :environment, :development

@@settings = YAML.load_file 'config/settings.yaml'

get '/' do
  erb :layout
end

get '/device/:device' do |device|
  # Start timer
  beginning = Time.now

  pg = pg_connect
  query = 'SELECT * FROM current WHERE device=$1'
  interfaces = populate(pg, query, { params: [device], device: device } ) || {}
  pg.close

  # How long did it take us to query the database
  db_elapsed = '%.2f' % (Time.now - beginning)

  erb :device, :locals => { :interfaces => interfaces }
end

# DB Connection
def pg_connect
  PG::Connection.new(
    :host => @@settings['pg_conn']['host'],
    :dbname => @@settings['pg_conn']['db'],
    :user => @@settings['pg_conn']['user'],
    :password => @@settings['pg_conn']['pass'])
end

# Return a hash with the data requested
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

### 
# HELPER METHODS -- THESE NEED TO GO SOMEWHERE ELSE 
###
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
  number_to_human(oids['ifHighSpeed'], :bps, true)
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

def interface_link(oids)
  "<a href='#{@@settings['grafana_if_dash']}" +
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

def number_to_human(raw, unit, si)
  i = 0
  units = {
    :bps => [' bps', ' Kbps', ' Mbps', ' Gbps', ' Tbps', ' Pbps', ' Ebps', ' Zbps', ' Ybps'],
    :pps => [' pps', ' Kpps', ' Mpps', ' Gpps', ' Tpps', ' Ppps', ' Epps', ' Zpps', ' Ypps'],
    :si_short => [' b', ' K', ' M', ' G', ' T', ' P', ' E', ' Z', ' Y'],
  }
  step = si ? 1000 : 1024
  while raw > step do
    raw = raw.to_f / step
    i += 1
  end
  return (sprintf "%.2f", raw.to_f) + units[i]
end
