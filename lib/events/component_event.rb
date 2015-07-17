# component_event.rb
#
require 'logger'
require 'json'
require_relative '../event'
$LOG ||= Logger.new(STDOUT)

class ComponentEvent < Event


  def self.fetch(device: nil, hw_type: nil, index: nil, comp_id: nil,
                 start_time: nil, end_time: nil, types: [ 'all' ], limit: nil)

    if (device && hw_type && index)
      resource = "/v2/events/component/#{device}/#{hw_type}/#{index}"
    elsif comp_id
      resource = "/v2/events/component/#{comp_id}"
    else
      resource = "/v2/events/component"
    end

    params = "types=#{types.join(',')}"
    params += "&start_time=#{start_time}" if start_time
    params += "&end_time=#{end_time}" if end_time
    params += "&limit=#{limit}" if limit && limit.to_s =~ /^[0-9]+$/

    result = API.get(
      src: 'component_event',
      dst: 'core',
      resource: "#{resource}?#{params}",
      what: "component events"
    )
    result.each do |object|
      unless object.is_a?(ComponentEvent)
        raise "Received bad object in ComponentEvent.fetch"
        return []
      end
    end
    return result
  end


  def self.fetch_from_db(device: nil, index: nil, hw_type: nil, comp_id: nil,
                         types:, db:, start_time: nil, end_time: nil, limit: nil)
    if (device && hw_type && index)
      comp_id = Component.id_from_db(device: device, index: index, hw_type: hw_type, db: db)
    end

    event_data = db[:component_event]
    # Filter if options were passed
    event_data = event_data.where(:component_id => comp_id) if comp_id
    event_data = event_data.where(:device => device) if device
    event_data = event_data.where(:hw_type => hw_type) if hw_type
    event_data = event_data.where{:time >= start_time} if start_time
    event_data = event_data.where{:time <= end_time} if end_time
    event_data = event_data.where(:subtype => types) unless (types.nil? || types.include?('all'))
    event_data = event_data.order(Sequel.desc(:time))
    event_data = event_data.limit(limit) if limit && limit.to_s =~ /^\d+$/
    event_data = event_data.join(:component, [:component_id])

    events = []
    event_data.select_all.each do |row|
      row[:data] = JSON.parse row[:data] if row[:data].class == String
      event = Object::const_get(row[:subtype]).new(
        device: row[:device], hw_type: row[:hw_type], index: row[:index],
        time: row[:time]
      )
      events.push(event.populate(row))
    end

    return events
  end


  def initialize(device: nil, hw_type: nil, index: nil, comp_id: nil, time:)
    return nil unless (device && hw_type && index) || comp_id
    # Event#new
    super(time: time)

    @device = device.to_s
    @hw_type = hw_type.to_s
    @index = index.to_s
    @component_id = comp_id.to_i_if_numeric
    @subtype = self.class.name
  end


  def component_id
    @component_id
  end


  def set_component_id(comp_id)
    return nil unless comp_id =~ /^[0-9]+$/
    @component_id = comp_id
    return self
  end


  def device
    @device
  end


  def hw_type
    @hw_type
  end


  def index
    @index
  end


  def subtype
    @subtype
  end


  def html_details(component=nil)
    "ERROR: html_details method not implemented in class #{self.class}"
  end


  def populate(data)
    # Required in order to accept symbol and non-symbol keys
    data = data.symbolize

    return nil unless super && data.class == Hash && !data.empty?

    # Return nil if we didn't find any data
    # TODO: Raise an exception instead?
    return nil if data.empty?

    @component_id = data[:component_id].to_i_if_numeric
    @subtype = data[:subtype]
    @device = data[:device]
    @hw_type = data[:hw_type]
    @index = data[:index]

    return self
  end


  def save(db:, data:)
    # Don't allow saving empty events
    return nil if !data || data.empty?
    begin

      @component_id ||= Component.id_from_db(
        device: @device, index: @index, hw_type: @hw_type, db: db
      )
      # Don't allow saving an event for a non-existant component
      return nil unless @component_id

      data = {
        :component_id => @component_id,
        :subtype => @subtype,
        :time => @time,
        :data => data.to_json
      }

      @id = db[:component_event].insert(data)
      raise "Didn't get event ID for new event!" unless @id
    rescue Sequel::NotNullConstraintViolation, Sequel::ForeignKeyConstraintViolation => e
      $LOG.error("Component Event: Save failed. #{e.to_s.gsub(/\n/,'. ')}")
      return nil
    end

    return self
  end


  def to_json(*a)
    hash = {
      "json_class" => self.class.name,
      "data" => {}
    }

    hash['data']["component_id"] = @component_id
    hash['data']["subtype"] = @subtype
    hash['data']["hw_type"] = @hw_type
    hash['data']["device"] = @device
    hash['data']["index"] = @index
    hash['data'].merge!( JSON.parse(super)['data'] )

    hash.to_json(*a)
  end


  def self.json_create(json)
    data = json["data"]
    obj = ComponentEvent.new(
      device: data['device'], hw_type: data['hw_type'], index: data['index'],
      time: data['time'], comp_id: data['component_id']
    )
    obj.populate(data)
  end


end
