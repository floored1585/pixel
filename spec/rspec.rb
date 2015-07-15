require_relative '../lib/sq'
require_relative '../lib/device'
require_relative '../lib/components/interface'
require_relative '../lib/components/cpu'
require_relative '../lib/components/fan'
require_relative '../lib/components/memory'
require_relative '../lib/components/psu'
require_relative '../lib/components/temperature'
require_relative '../lib/event'
require_relative '../lib/events/component_event'
require_relative '../lib/events/component_events/description_change_event'

require_relative 'objects'

$LOG = Logger.new('/dev/null')

DB = SQ.initiate
