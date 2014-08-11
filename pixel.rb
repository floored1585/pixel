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

    # Start timer
    beginning = Time.now

    pg = pg_connect(settings)
    query_bb_down = "
      SELECT * FROM current
      WHERE
        ( ifalias LIKE 'sub%' OR ifalias LIKE 'bb%' )
        AND ifoperstatus != 1
        AND device<>'test'"
    query_dis = "
      SELECT * FROM current
      WHERE discardsout > 9
      AND ifalias NOT LIKE 'sub%'
      AND device<>'test'
      ORDER BY discardsout DESC
      LIMIT 10"
    query_sat = "
      SELECT * FROM current
      WHERE ( bpsin_util > 90 OR bpsout_util > 90 )
      AND device<>'test'
      LIMIT 10"

    ints_down = populate(settings, pg, query_bb_down)

    # Remove from down list if parent interface is down
    # and parent interface is on the same device.
    ints_down.each do |device,interfaces|
      interfaces.delete_if do |index,oids|
        oids['myParent'] &&
          interfaces[oids['myParent']]
      end
    end

    ints_dis = populate(settings, pg, query_dis)
    ints_sat = populate(settings, pg, query_sat)
    pg.close

    # How long did it take us to query the database
    db_elapsed = '%.2f' % (Time.now - beginning)

  erb :dashboard, :locals => {
    :title => 'Dashboard!',
    :settings => settings,
    :ints_dis => ints_dis,
    :ints_sat => ints_sat,
    :ints_down => ints_down,
  }
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
    :settings => settings,
    :device => device,
    :interfaces => interfaces,
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


