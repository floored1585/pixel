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

# config_item.rb
#
require 'logger'
require 'json'
$LOG ||= Logger.new(STDOUT)

class ConfigItem


  def self.fetch_from_db(db:, table:, setting:)
    settings = {}

    config_db = db[table.to_sym]

    config_db.where(table: table) if table
    config_db.where(setting: setting) if setting

    config_db.each do |row|
      settings[row[:setting]] = ConfigItem.new(row)
    end

    return settings
  end


  def self.populate(table_name:, data:)
    return nil unless data

    data = data.symbolize

    ConfigItem.new(
      table_name: table_name.to_sym,
      setting: data[:setting],
      value: data[:value],
      description: data[:description],
      type: data[:type],
      last_updated: data[:last_updated]
    )
  end


  def initialize(table_name:, setting:, value:, description:, type:, last_updated: Time.now.to_i)

    @table_name = table_name.to_sym
    @setting = setting
    @value = value
    @description = description
    @type = type
    @last_updated = last_updated

  end


  def value
    case @type
    when 'String'
      @value.to_s
    when 'Integer'
      Integer(@value) # rescue nil ??
    when 'Boolean'
      @value == 'true'
    when 'Array'
      JSON.parse(@value)
    end
  end


  def description
    @description.to_s
  end


  def last_updated
    @last_updated.to_i
  end


  def save(db)
    begin
      data = {
        table_name: @table_name.to_s,
        setting: @setting,
        value: @value,
        description: @description,
        type: @type,
        last_updated: @last_updated
      }

      existing = db[@table_name.to_sym].where(setting: @setting.to_s)
      if existing.update(data) != 1
        db[@table_name.to_sym].insert(data)
      end
    rescue Sequel::NotNullConstraintViolation, Sequel::ForeignKeyConstraintViolation => e
      $LOG.error("CONFIG_ITEM: Save failed. #{e.to_s.gsub(/\n/,'. ')}")
      return nil
    end

    return self
  end


  def to_json(*a)
    hash = {
      "json_class" => self.class.name,
      "data" => {}
    }

    hash['data']['table_name'] = @table_name
    hash['data']['setting'] = @setting
    hash['data']['value'] = @value
    hash['data']['description'] = @description
    hash['data']['type'] = @type
    hash['data']['last_updated'] = @last_updated

    hash.to_json(*a)
  end


  def self.json_create(json)
    data = json['data']
    return ConfigItem.new(
      table_name: data['table_name'],
      setting: data['setting'],
      value: data['value'],
      description: data['description'],
      type: data['type'],
      last_updated: data['last_updated']
    )
  end


  private # All methods below are private!!


end
