require 'sinatra'
require 'yaml'
require 'sinatra/reloader'
require 'pg'
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
  erb :dashboard
end

get '/device/search' do
    target = params[:device_input] || 'Enter a device in the search box'
    redirect to(target.empty? ? '/' : "/device/#{target}")
end

get '/device/:device' do |device|
  # Start timer
  beginning = Time.now

  pg = pg_connect(settings)
  query = 'SELECT * FROM current WHERE device=$1'
  interfaces = Pixel::populate(settings, pg, query, { params: [device], device: device } ) || {}
  pg.close

  # How long did it take us to query the database
  db_elapsed = '%.2f' % (Time.now - beginning)

  erb :device, :locals => { 
    :interfaces => interfaces, 
    :settings => settings 
  }
end

# DB Connection
def pg_connect(settings)
  PG::Connection.new(
    :host => settings['pg_conn']['host'],
    :dbname => settings['pg_conn']['db'],
    :user => settings['pg_conn']['user'],
    :password => settings['pg_conn']['pass'])
end


