require_relative '../lib/sq'
require_relative '../lib/device'
require_relative '../lib/interface'
require_relative '../lib/cpu'
require_relative '../lib/fan'
require_relative '../lib/memory'
require_relative '../lib/psu'
require_relative '../lib/temperature'
require_relative '../lib/event'

require_relative 'objects'

$LOG = Logger.new('/dev/null')

DB = SQ.initiate
