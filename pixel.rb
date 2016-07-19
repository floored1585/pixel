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

require 'sinatra/base'
require 'yaml'
require 'pp'
require 'rack/coffee'
require 'json'
require 'logger'
require 'rufus-scheduler'

# Load the modules
Dir["#{File.dirname(__FILE__)}/lib/**/*.rb"].each { |file| require(file) }

APP_ROOT = File.dirname(__FILE__)
$LOG = Logger.new("#{APP_ROOT}/messages.log", 0, 100*1024*1024)
$LOG.info "Starting Pixel..."

# When $DB_VERSION increases a schema update is triggered.  Make sure
# there is a matching db_update_#.sql file in the config directory
# before increasing this.
$DB_VERSION = 2

class Pixel < Sinatra::Base

  @@scheduler = Rufus::Scheduler.new(:lockfile => ".rufus-scheduler.lock")

  # Will return nil if this is an api_only instance
  @@db = SQ.initiate

  if @@db
    @@db.disconnect
    @@config = Config.fetch_from_db(db: @@db)
    @@config.save(@@db)
  else
    @@config = Config.fetch
  end

  include Core
  include Helper

  @@instance = nil

  # Don't set up recurring jobs if scheduler is down
  unless @@scheduler.down?

    @@scheduler.in('1s') do
      @@instance = Instance.fetch(hostname: Socket.gethostname).first || Instance.new
    end

    poller = @@scheduler.schedule_every('2s') do
      Poller.check_for_work(@@instance, @@config) unless @@instance && @@instance.hostname.empty?
    end
    poller.pause

    @@scheduler.every('5s') do
      restart = false

      new_instance = Instance.fetch(hostname: @@instance.hostname || Socket.gethostname).first || Instance.new

      if new_instance.to_json != @@instance.to_json
        # Our instance data doesn't match the database, restart!
        restart = true
      else
        restart = false
      end

      @@instance = new_instance

      @@instance.update!(config: @@config)

      if @@instance.config_hash != Config.fetch_hash
        $LOG.info('INSTANCE: Configuration is outdated, fetching new config...')
        @@config = @@config.reload
        @@instance.update!(config: @@config)
        restart = true
      end

      @@instance.send

      if restart
        $LOG.info('INSTANCE: Configuration or instance data was updated... restarting!')
        FileUtils.touch('tmp/restart.txt')
      else
        if @@instance.poller?
          if poller.paused?
            $LOG.info('INSTANCE: Starting poller!')
            poller.resume
          end
        else
          unless poller.paused?
            $LOG.info('INSTANCE: Stopping poller!')
            poller.pause
          end
        end

        if @@instance.master?
          AlertEngine.process_events(@@db, @@config)
        end
      end
    end

  end

  # COFFEESCRIPT PLZ
  use Rack::Coffee, root: 'public', urls: '/javascripts'

end

# Load the routes
Dir["#{File.dirname(__FILE__)}/routes/**/*.rb"].each { |file| require(file) }
