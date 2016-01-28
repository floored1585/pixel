Dir["#{File.dirname(__FILE__)}/../lib/**/*.rb"].each { |file| require(file) }

require_relative 'objects'

$LOG = Logger.new('/dev/null')

DB = SQ.initiate

SETTINGS = Config.fetch_from_db(db: DB).settings
