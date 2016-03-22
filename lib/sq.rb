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

    # Throw an error if we're missing something
    unless (host && user && pass && database && pool_timeout && max_connections)
      $LOG.error("DB: Missing host in config.yaml!") unless host
      $LOG.error("DB: Missing user in config.yaml!") unless user
      $LOG.error("DB: Missing pass in config.yaml!") unless pass
      $LOG.error("DB: Missing database in config.yaml!") unless database
      $LOG.error("DB: Missing pool_timeout in config.yaml!") unless pool_timeout
      $LOG.error("DB: Missing max_connections in config.yaml!") unless max_connections
      return nil
    end

    db = Sequel.connect(
      :adapter => 'postgres',
      :host => host,
      :user => user,
      :password => pass,
      :database => database,
      :pool_timeout => pool_timeout,
      :max_connections => max_connections
    )

    if db.table_exists?(:meta)
      # Existing DB, check if we need to update

      db_version = db[:meta].first[:db_version]

      while db_version < ($DB_VERSION || 0)
        # We need to process a schema update!

        $LOG.info("SEQUEL: Upgrading database schema from version #{db_version} to #{db_version + 1}...")
        db_version += 1
        upgrade_statements = []

        File.open("config/db_update_#{db_version}.sql") do |file|
          upgrade_statements = file.read.gsub(/\s+/, ' ').split('; ')
        end

        upgrade_statements.each do |statement|
          db.run(statement)
        end
      end

    else
      # Fresh DB, populate it!

      $LOG.info("SEQUEL: New database detected; Importing schema...")

      statements = []

      File.open('config/db_init.sql') do |file|
        statements = file.read.gsub(/\s+/, ' ').split('; ')
      end

      statements.each do |statement|
        db.run(statement)
      end

    end

    # Give the DB handle back to the app
    return db
  end

end
