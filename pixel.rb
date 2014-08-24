require 'sinatra/base'
require 'yaml'
require 'pp'
require 'rack/coffee'
require 'json'

# Load the modules
Dir["#{File.dirname(__FILE__)}/lib/**/*.rb"].each { |file| require(file) }

APP_ROOT = File.dirname(__FILE__)

class Pixel < Sinatra::Base

  @@settings = Configfile.retrieve
  @@db = SQ.initiate
  @@db.disconnect

  include Core
  include Helper

  # COFFEESCRIPT PLZ
  use Rack::Coffee, root: 'public', urls: '/javascripts'

end

# Load the routes
Dir["#{File.dirname(__FILE__)}/routes/**/*.rb"].each { |file| require(file) }
