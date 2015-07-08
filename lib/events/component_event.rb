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


  def component_id
    @component_id
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


  def save(db)
    begin

      @component_id = db[:component].where(:device=>@device, :hw_type=>@hw_type, :index=>@index).first[:id]
      raise "Can't find component ID: #{@device}, #{@hw_type}, #{@index}" unless @component_id

      data = { :component_id=>@component_id, :subtype=>@subtype, :time=>@time, :data=>@data }

      @id = db[:component_event].insert(data)
      raise "Didn't get event ID for new event!" unless @id
    rescue Sequel::NotNullConstraintViolation, Sequel::ForeignKeyConstraintViolation => e
      $LOG.error("Component Event: Save failed. #{e.to_s.gsub(/\n/,'. ')}")
      return nil
    end

    return self
  end


end
