require 'sinatra/base'
require 'yaml'
require 'pp'
require 'rack/coffee'
require 'json'
require 'logger'

# Load the modules
Dir["#{File.dirname(__FILE__)}/lib/**/*.rb"].each { |file| require(file) }

APP_ROOT = File.dirname(__FILE__)
$LOG = Logger.new("#{APP_ROOT}/messages.log", 0, 100*1024*1024)

class Pixel < Sinatra::Base

  @@settings = Configfile.retrieve
  @@db = SQ.initiate
  @@db.disconnect

  include Core
  include Helper

  if @@settings['this_is_poller']
    Core.start_cron(@@settings)
  end

  # COFFEESCRIPT PLZ
  use Rack::Coffee, root: 'public', urls: '/javascripts'

end

# Load the routes
Dir["#{File.dirname(__FILE__)}/routes/**/*.rb"].each { |file| require(file) }
