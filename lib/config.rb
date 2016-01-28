# config.rb
#
require 'logger'
require 'json'
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
    config_db = db[:global_config].to_hash(:setting)
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

    @settings[:grafana_if_dash] ||= ConfigItem.new(
      table_name: 'global_config',
      setting: 'grafana_if_dash',
      value: 'http://127.0.0.1/#/dashboard/script/ne_interface.js',
      description: 'Link to the Grafana interface scripted dashboard',
      type: 'String',
      last_updated: now
    )
    @settings[:grafana_dev_dash] ||= ConfigItem.new(
      table_name: 'global_config',
      setting: 'grafana_dev_dash',
      value: 'http://127.0.0.1/#/dashboard/script/ne_device.js',
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

  end


  def settings
    @settings
  end


  def reload
    Config.fetch
  end


  def hash
    Digest::MD5.hexdigest(Marshal::dump(self))
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
