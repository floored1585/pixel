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

# component_status_event.rb
#
require 'logger'
require 'json'
require_relative '../component_event'
$LOG ||= Logger.new(STDOUT)

class ComponentStatusEvent < ComponentEvent


  def initialize(device: nil, hw_type: nil, index: nil, comp_id: nil,
    time: Time.now.to_i, old: nil, new: nil)
    return nil unless (device && hw_type && index) || comp_id
    # ComponentEvent#new
    super(
      device: device, hw_type: hw_type, index: index,
      time: time, comp_id: comp_id
    )
    @old = old
    @new = new
  end


  def old
    @old
  end


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
    obj = Object::const_get(data['subtype']).new(
      device: data['device'], hw_type: data['hw_type'], index: data['index'],
      time: data['time'], comp_id: data['comp_id']
    )
    obj.populate(data)
  end


  def get_email(db)
    component = Component.fetch_from_db(id: @component_id, db: db).first
    {
      subject: "#{component.description} (#{component.hw_type}) on #{component.device}: #{@new}",
      body: ""
    }
  end


end
