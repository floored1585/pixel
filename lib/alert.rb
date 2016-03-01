# alert.rb
#
require 'logger'
require 'json'
require_relative 'core_ext/object'
$LOG ||= Logger.new(STDOUT)


class Alert


  def device
    @device
  end


  def hw_type
    @hw_type
  end


  def index
    @index
  end


  def type
    @type
  end


  def save
  end


end
