require 'sinatra'
require 'yaml'
require 'sinatra/reloader'
require 'pg'

require_relative 'lib/core_ext/string.rb'
require_relative 'lib/yaml'
require_relative 'lib/sequel'
require_relative 'lib/base'
require_relative 'lib/helper'

set :environment, :development

include Configfile
include SQ
include Pixel
include Helper

settings = Configfile.retrieve
db_handle = SQ.initiate

get '/' do
  erb :dashboard
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

  
