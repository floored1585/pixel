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
      Poller.check_for_work(@@instance) unless @@instance && @@instance.hostname.empty?
    end
    poller.pause

    @@scheduler.every('5s') do
      @@instance = Instance.fetch(hostname: @@instance.hostname || Socket.gethostname).first || Instance.new
      @@instance.update!(config: @@config)

      if @@instance.config_hash != Config.fetch_hash
        $LOG.info('INSTANCE: Configuration is outdated, fetching new config...')
        @@config = @@config.reload
        @@instance.update!(config: @@config)
      end

      @@instance.send

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
    end

  end

  # COFFEESCRIPT PLZ
  use Rack::Coffee, root: 'public', urls: '/javascripts'

end

# Load the routes
Dir["#{File.dirname(__FILE__)}/routes/**/*.rb"].each { |file| require(file) }
