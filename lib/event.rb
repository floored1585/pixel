# event.rb
#
require 'logger'
require 'securerandom'
require_relative 'alert'
require_relative 'component'
$LOG ||= Logger.new(STDOUT)

class Event


  # Returns hash where keys are the class and values are the friendly event name
  def self.get_types(db)
    db[:component_event].distinct.select_map(:subtype).map do |type|
      { type => Object::const_get(type).friendly_subtype }
    end
  end


  def self.get_unprocessed
    events = []
    events += ComponentEvent.fetch(processed: false)
  end


  def self.friendly_subtype
    'Event'
  end


  def initialize(time:)
    unless time.to_s =~ /^[0-9]+$/
      raise TypeError.new("timestamp (#{time}) must look like an Integer!")
    end

    @time = time.to_i
    @processed = false
  end


  def time
    @time
  end


  def id
    @id
  end


  def processed?
    !!@processed
  end


  def process!
    @processed = true
    return self
  end


  def get_alert
    $LOG.error("EVENT: get_alert method not implemented in class #{self.class}")
    return nil
  end


  def populate(data)
    # Required in order to accept symbol and non-symbol keys
    data = data.symbolize

    # Return nil if we didn't find any data
    # TODO: Raise an exception instead?
    return nil if data.empty?

    @id = data[:event_id].to_i_if_numeric
    @time = data[:time].to_i_if_numeric

    return self
  end


  def to_json(*a)
    hash = {
      "json_class" => self.class.name,
      "data" => {}
    }

    hash['data']["event_id"] = @id
    hash['data']["time"] = @time

    hash.to_json(*a)
  end


end
