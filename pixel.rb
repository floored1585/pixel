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
  @@settings = Configfile.retrieve
  @@db = SQ.initiate
  @@db.disconnect

  include Core
  include Helper

  @@instance = nil

  if @@settings['this_is_poller']
    @@scheduler.every('2s') do
      Poller.check_for_work(@@settings, @@instance) unless @@instance && @@instance.hostname.empty?
    end
  end

  # Don't set up recurring jobs if scheduler is down
  unless @@scheduler.down?

    @@scheduler.in('2s') do
      @@instance = Instance.fetch(hostname: Socket.gethostname).first || Instance.new
    end

    @@scheduler.every('5s') do
      @@instance.update!(settings: @@settings)
      @@instance.send
    end

  end

  # COFFEESCRIPT PLZ
  use Rack::Coffee, root: 'public', urls: '/javascripts'

end

# Load the routes
Dir["#{File.dirname(__FILE__)}/routes/**/*.rb"].each { |file| require(file) }
