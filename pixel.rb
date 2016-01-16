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

  @@scheduler = Rufus::Scheduler.new
  @@settings = Configfile.retrieve
  @@db = SQ.initiate
  @@db.disconnect

  include Core
  include Helper

  @@instance = Instance.fetch_from_db(db: @@db, hostname: Socket.gethostname).first || Instance.new

  if @@settings['this_is_poller']
    @@scheduler.every('2s') do
      Poller.check_for_work(@@settings, @@instance) unless @@instance.hostname.empty?
    end
  end

  @@scheduler.every('5s') do
    @@instance.update!(settings: @@settings)
    @@instance.save(@@db)
    $LOG.info('CORE: Instance update completed')
  end

  # COFFEESCRIPT PLZ
  use Rack::Coffee, root: 'public', urls: '/javascripts'

end

# Load the routes
Dir["#{File.dirname(__FILE__)}/routes/**/*.rb"].each { |file| require(file) }
