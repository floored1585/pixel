# component.rb
#
require 'logger'

$LOG ||= Logger.new(STDOUT)


class Component


  def self.fetch(device, index, type)
    obj = API.get(
      src: 'component',
      dst: 'core',
      resource: "/v2/device/#{device}/#{type}/#{index}",
      what: "#{type} #{index} on #{device}",
    )
    obj.is_a?(Component) ? obj : nil
  end


  def initialize(device:, index:)
    @device = device
    @index = index.to_s
  end


  def last_updated
    @last_updated || 0
  end


  def device
    @device
  end


  def index
    @index
  end


  def description
    @description || ''
  end


  def populate(data)
    # Required in order to accept symbol and non-symbol keys
    data = data.symbolize

    # Return nil if we didn't find any data
    # TODO: Raise an exception instead?
    return nil if data.empty?

    @description = data[:description].to_s
    @last_updated = data[:last_updated].to_i_if_numeric
    @worker = data[:worker]

    return self
  end


  def update(data, worker:)
    new_description = data['description'] || "##{@index}"
    current_time = Time.now.to_i
    new_worker = worker

    @description = new_description
    @last_updated = current_time
    @worker = new_worker

    return self
  end


end
