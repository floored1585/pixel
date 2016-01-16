Dir["#{File.dirname(__FILE__)}/../lib/**/*.rb"].each { |file| require(file) }

require_relative 'objects'

$LOG = Logger.new('/dev/null')

SETTINGS = Configfile.retrieve

DB = SQ.initiate
