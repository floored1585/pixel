# description_change_event.rb
#
require 'logger'
require_relative 'component_event'
$LOG ||= Logger.new(STDOUT)

class DescriptionChangeEvent < ComponentEvent


  def initialize(device:, hw_type:, index:, old:, new:, time: Time.now.to_i)
    # ComponentEvent#new
    super(device: device, hw_type: hw_type, index: index, time: time)

    @old = old
    @new = new
    @subtype = 'description_change'
  end


  # Old description
  def old
    @old
  end


  # New description
  def new
    @new
  end


end
