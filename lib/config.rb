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

# config.rb
#
require 'logger'
require 'json'
require_relative 'api'
require_relative 'core_ext/hash'
$LOG ||= Logger.new(STDOUT)

class Config


  def self.fetch_hash
    result = API.get(
      src: 'instance',
      dst: 'core',
      resource: '/v2/config_hash',
      what: 'configuration hash',
    )
    unless result.is_a?(Array)
      raise "Received bad object in Config.fetch_hash"
      return nil
    end
    return result.first
  end


  def self.fetch
    result = API.get(
      src: 'instance',
      dst: 'core',
      resource: '/v2/config',
      what: 'configuration',
    )
    unless result.is_a?(Config)
      raise "Received bad object in Config.fetch"
      return nil
    end
    return result
  end


  def self.fetch_from_db(db:)
    # .order is important here, to get a consistent hash of the config
    config_db = db[:global_config].order(:setting).to_hash(:setting)
    Config.new(config_db)
  end


  def populate(data)
    # Required in order to accept symbol and non-symbol keys
    data = data.symbolize

    # Return nil if we didn't find any data or if the data
    # isn't a hash of ConfigItems
    # TODO: Raise an exception instead?
    return nil if data.empty?
    data.values.each do |config_item|
      return nil unless config_item.class == ConfigItem
    end

    @settings = data

    return self
  end


  def initialize(config_db = {})

    now = Time.now.to_i

    @settings = {}

    config_db.each do |setting, data|
      @settings[setting.to_sym] = ConfigItem.populate(table_name: 'global_config', data: data)
    end

    # NOTE: 'value' should always be a string here.  It is casted when accessed based on 'type'.

    @settings[:grafana_if_dash] ||= ConfigItem.new(
      table_name: 'global_config',
      setting: 'grafana_if_dash',
      value: 'http://127.0.0.1:3000/#/dashboard/script/interface.js',
      description: 'Link to the Grafana interface scripted dashboard',
      type: 'String',
      last_updated: now
    )
    @settings[:grafana_dev_dash] ||= ConfigItem.new(
      table_name: 'global_config',
      setting: 'grafana_dev_dash',
      value: 'http://127.0.0.1:3000/#/dashboard/script/device.js',
      description: 'Link to the Grafana device scripted dashboard',
      type: 'String',
      last_updated: now
    )
    @settings[:stale_timeout] ||= ConfigItem.new(
      table_name: 'global_config',
      setting: 'stale_timeout',
      value: "500",
      description: 'Number of seconds before polled data is considered stale',
      type: 'Integer',
      last_updated: now
    )
    @settings[:notifications_enabled] ||= ConfigItem.new(
      table_name: 'global_config',
      setting: 'notifications_enabled',
      value: "false",
      description: 'Whether or not to send alert notification emails',
      type: 'Boolean',
      last_updated: now
    )
    @settings[:notification_recipients] ||= ConfigItem.new(
      table_name: 'global_config',
      setting: 'notification_recipients',
      value: "",
      description: 'Comma separated list of email addresses that will receive notifications',
      type: 'String',
      last_updated: now
    )
    @settings[:notification_from_email] ||= ConfigItem.new(
      table_name: 'global_config',
      setting: 'notification_from_email',
      value: "",
      description: 'Email address from which alert notification emails will originate',
      type: 'String',
      last_updated: now
    )
    @settings[:notification_from_name] ||= ConfigItem.new(
      table_name: 'global_config',
      setting: 'notification_from_name',
      value: "Pixel Notification",
      description: 'Name from which alert notification emails will originate',
      type: 'String',
      last_updated: now
    )
    @settings[:poller_concurrency] ||= ConfigItem.new(
      table_name: 'global_config',
      setting: 'poller_concurrency',
      value: "10",
      description: 'How many devices a poller will poll concurrently',
      type: 'Integer',
      last_updated: now
    )
    @settings[:influx_ip] ||= ConfigItem.new(
      table_name: 'global_config',
      setting: 'influx_ip',
      value: "127.0.0.1",
      description: 'IP address of the InfluxDB installation',
      type: 'String',
      last_updated: now
    )
    @settings[:influx_user] ||= ConfigItem.new(
      table_name: 'global_config',
      setting: 'influx_user',
      value: "user",
      description: 'InfluxDB username',
      type: 'String',
      last_updated: now
    )
    @settings[:influx_pass] ||= ConfigItem.new(
      table_name: 'global_config',
      setting: 'influx_pass',
      value: "pass",
      description: 'InfluxDB password',
      type: 'String',
      last_updated: now
    )
    @settings[:influx_db_name] ||= ConfigItem.new(
      table_name: 'global_config',
      setting: 'influx_db_name',
      value: "pixel",
      description: 'InfluxDB database name',
      type: 'String',
      last_updated: now
    )
    @settings[:base_url] ||= ConfigItem.new(
      table_name: 'global_config',
      setting: 'base_url',
      value: "http://127.0.0.1",
      description: 'URL of the Pixel frontend',
      type: 'String',
      last_updated: now
    )
    @settings[:snmpv2_community] ||= ConfigItem.new(
      table_name: 'global_config',
      setting: 'snmpv2_community',
      value: "public",
      description: 'SNMPv2 community string',
      type: 'String',
      last_updated: now
    )
    @settings[:event_notify_types] ||= ConfigItem.new(
      table_name: 'global_config',
      setting: 'event_notify_types',
      value: "[]",
      description: 'List of events that will generate notifications',
      type: 'Array',
      last_updated: now
    )

    # Allow acessing config items with @@config.config_item_name
    @settings.each do |config_item_name, config_item|
      self.class.send(:define_method, config_item_name) do
        settings[config_item_name.to_sym]
      end
    end

  end


  def settings
    @settings
  end


  def reload
    Config.fetch
  end


  def hash
    Digest::MD5.hexdigest(Marshal::dump(self.to_json))
  end


  def save(db)
    save_went_ok = true
    @settings.each do |name, config_item|
      item_saved = !!(config_item.save(db))
      save_went_ok = save_went_ok && item_saved
    end
    return self if save_went_ok
    return nil
  end


  def send
    start = Time.now.to_i
    if API.post(
      src: 'config',
      dst: 'core',
      resource: '/v2/config',
      what: "configuration",
      data: to_json
    )
      elapsed = Time.now.to_i - start
      $LOG.info("CONFIG: POST successful (#{elapsed} seconds)")
      return self
    else
      $LOG.error("CONFIG: POST failed; Aborting")
      return nil
    end
  end


  def to_json(*a)
    hash = {
      "json_class" => self.class.name,
      "data" => {}
    }

    hash['data'] = @settings

    hash.to_json(*a)
  end


  def self.json_create(json)
    data = json['data']
    return Config.new.populate(data)
  end


  private # All methods below are private!!


end
