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

# event.rb
#
require 'logger'
require 'securerandom'
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


  # Overridden in individual event classes
  def get_email(db)
    $LOG.error "ERROR: get_email method not implemented in class #{self.class}"
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
