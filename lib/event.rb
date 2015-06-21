# event.rb
#
require 'logger'
require 'securerandom'
require_relative 'component'
$LOG ||= Logger.new(STDOUT)

class Event


  def initialize(time:)
    unless time.to_s =~ /^[0-9]+$/
      raise TypeError.new("timestamp (#{time}) must look like an Integer!")
    end

    @type = type
    @time = time.to_i
    @id = SecureRandom.uuid
    @type = nil # Should be set in subclass
  end


  def time
    @time
  end


  def id
    @id
  end


  def type
    @type
  end

end
