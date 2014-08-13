require 'sinatra'
require 'yaml'
require 'sinatra/reloader'
require 'pg'
require 'pp'
require 'rack/coffee'

# Load the modules
Dir["#{File.dirname(__FILE__)}/lib/**/*.rb"].each { |f| require(f) }

include Configfile
include SQ
include Pixel
include Helper

settings = Configfile.retrieve
db = SQ.initiate

# COFFEESCRIPT PLZ
use Rack::Coffee, root: 'public', urls: '/javascripts'

get '/' do
  # Start timer
  beginning = Time.now

  ints_saturated = get_ints_saturated(settings, db)
  ints_discarding = get_ints_discarding(settings, db)
  ints_down = get_ints_down(settings, db)

  db_elapsed = '%.2f' % (Time.now - beginning)

  erb :dashboard, :locals => {
    :title => 'Dashboard!',
    :settings => settings,
    :ints_discarding => ints_discarding,
    :ints_saturated => ints_saturated,
    :ints_down => ints_down,
    :db_elapsed => db_elapsed,
  }
end

get '/device/search' do
  target = params[:device_input] || 'Enter a device in the search box'
  redirect to(target.empty? ? '/' : "/device/#{target}")
end


get '/device/:device' do |device|
  # Start timer
  beginning = Time.now

  interfaces = get_ints_device(settings, db, device)

  # How long did it take us to query the database
  db_elapsed = '%.2f' % (Time.now - beginning)

  erb :device, :locals => {
    :settings => settings,
    :device => device,
    :interfaces => interfaces[device],
    :db_elapsed => db_elapsed,
  }
end

