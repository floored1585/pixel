# component_event.rb
#
require 'logger'
require_relative '../event'
$LOG ||= Logger.new(STDOUT)

class ComponentEvent < Event


  def initialize(device:, hw_type:, index:, time:)
    # Event#new
    super(time: time)

    @device = device.to_s
    @hw_type = hw_type.to_s
    @index = index.to_s
    @type = 'component'
    @subtype = nil # Should be set in subclass

  end


  def device
    @device
  end


  def hw_type
    @hw_type
  end


  def index
    @index
  end


  def subtype
    @subtype
  end


end
