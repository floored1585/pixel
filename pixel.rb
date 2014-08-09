require 'sinatra'
require 'yaml'
require 'sinatra/reloader'
require 'pg'

require_relative 'lib/core_ext/string.rb'
require_relative 'lib/yaml'
require_relative 'lib/sequel'

set :environment, :development

include Configfile
include SQ

settings = Configfile.retrieve
db_handle = SQ.initiate

get '/' do
  erb :layout
end

get '/device/:device' do |device|
  # Start timer
  beginning = Time.now

 # pg = pg_connect
 # query = 'SELECT * FROM current WHERE device=$1'
 # interfaces = populate(pg, query, { params: [device], device: device } ) || {}
  #pg.close

  # How long did it take us to query the database
  #db_elapsed = '%.2f' % (Time.now - beginning)

  erb :device#, :locals => { :interfaces => interfaces }
end

# DB Connection
#def pg_connect
#  PG::Connection.new(
#    :host => @@settings['pg_conn']['host'],
#    :dbname => @@settings['pg_conn']['db'],
#    :user => @@settings['pg_conn']['user'],
#    :password => @@settings['pg_conn']['pass'])
#end

  
