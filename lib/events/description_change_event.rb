# description_change_event.rb
#
require 'logger'
require_relative 'component_event'
$LOG ||= Logger.new(STDOUT)

class DescriptionChangeEvent < ComponentEvent


  def initialize(device: nil, hw_type: nil, index: nil, comp_id: nil,
    time: Time.now.to_i, old: nil, new: nil)
    return nil unless (device && hw_type && index) || comp_id
    # ComponentEvent#new
    super(
      device: device, hw_type: hw_type, index: index,
      time: time, comp_id: comp_id, subtype: self.class.name
    )
    @old = old.empty? ? nil : old
    @new = new.empty? ? nil : new
  end


  # Old description
  def old
    @old
  end


  # New description
  def new
    @new
  end


  def populate(data)
    # Required in order to accept symbol and non-symbol keys
    data = data.symbolize

    # If parent's #populate returns nil, return nil here also
    return nil unless super && data && data[:data].class == Hash

    @old = data[:data]['old']
    @new = data[:data]['new']

    return self
  end


  def save(db)
    data = {
      :old => @old,
      :new => @new,
    }
    super(db: db, data: data)
  end


  def to_json(*a)
    hash = {
      "json_class" => self.class.name,
      "data" => { 'data' => {} }
    }

    hash['data']['data']["old"] = @old
    hash['data']['data']["new"] = @new
    hash['data'].merge!( JSON.parse(super)['data'] )

    hash.to_json(*a)
  end


  def self.json_create(json)
    data = json["data"]
    obj = DescriptionChangeEvent.new(
      device: data['device'], hw_type: data['hw_type'], index: data['index'],
      time: data['time'], comp_id: data['comp_id']
    )
    obj.populate(data)
  end


end
