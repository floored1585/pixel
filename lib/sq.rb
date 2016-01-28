#!/usr/bin/env ruby

require 'sequel'

module SQ

  def self.initiate
    cfg = YAML.load_file(File.expand_path('../../config/config.yaml', __FILE__))

    return nil if cfg['api_only']

    host = cfg['host'] || '127.0.0.1'
    user = cfg['user']
    pass = cfg['pass']
    database = cfg['db'] || 'pixel'
    pool_timeout = cfg['pool_timeout'] || 10
    max_connections = cfg['max_connections'] || 10

    return nil unless (host && user && pass && database && pool_timeout && max_connections)

    Sequel.connect(
      :adapter => 'postgres',
      :host => host,
      :user => user,
      :password => pass,
      :database => database,
      :pool_timeout => pool_timeout,
      :max_connections => max_connections
    )
  end

end
