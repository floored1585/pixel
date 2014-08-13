require 'sinatra'
require 'yaml'
require 'sinatra/reloader'
require 'pg'
require 'pp'
require 'rack/coffee'

# Load the modules
Dir["#{File.dirname(__FILE__)}/lib/**/*.rb"].each { |f| require(f) }

set :environment, :development

include Configfile
include SQ
include Pixel
include Helper

settings = Configfile.retrieve
db_handle = SQ.initiate

# COFFEESCRIPT PLZ
use Rack::Coffee, root: 'public', urls: '/javascripts'

get '/' do
  # Start timer
  beginning = Time.now

  ints_saturated = interfaces_saturated(settings,db_handle)
  ints_discarded = interfaces_discarded(settings,db_handle)
  ints_down = interfaces_down(settings,db_handle)

  db_elapsed = '%.2f' % (Time.now - beginning)

  erb :dashboard, :locals => {
    :title => 'Dashboard!',
    :settings => settings,
    :ints_dis => ints_discarded,
    :ints_sat => ints_saturated,
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

  interfaces = device_interfaces(settings,db_handle,device)

  # How long did it take us to query the database
  db_elapsed = '%.2f' % (Time.now - beginning)

  erb :device, :locals => {
    :settings => settings,
    :device => device,
    :interfaces => interfaces,
    :db_elapsed => db_elapsed,
  }
end
