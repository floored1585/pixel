# cpu.rb
#
require 'logger'
require 'json'
require_relative 'api'
require_relative 'core_ext/object'
$LOG ||= Logger.new(STDOUT)

class CPU


  def initialize(device:, index:)

    # required
    @device = device
    @index = index

  end
  

  def populate(data=nil)

    # If we weren't passed data, look ourselves up
    data ||= API.get('core', "/v2/device/#{@device}/cpu/#{@index}", 'CPU', 'cpu data')
    # Return nil if we didn't find any data
    # TODO: Raise an exception instead?
    return nil if data.empty?

    @util = data['util'].to_i_if_numeric
    @description = data['description']
    @last_updated = data['last_updated'].to_i_if_numeric
    @worker = data['worker']

    return self
  end


  def update(data, worker:)

    # TODO: Data validation? See mac class for example

    new_util = data['util'].to_i
    new_description = data['description'] || "CPU #{@index}"
    current_time = Time.now.to_i
    new_worker = worker

    @util = new_util
    @description = new_description
    @last_updated = current_time
    @worker = new_worker

    return self
  end


  def write_influxdb
    Influx.post(
      series: "#{@device}.cpu.#{@index}.#{@description}",
      value: @util,
      time: @last_updated,
    )
  end


  def save(db)
    data = JSON.parse(self.to_json)['data']

    # Update the cpu table
    existing = db[:cpu].where(:device => @device, :index => @index)
    if existing.update(data) != 1
      db[:cpu].insert(data)
      $LOG.info("Adding new cpu #{@index} on #{@device} from #{@worker}")
    end

    return self
  end


  def delete(db)
    # Delete the cpu from the database
    count = db[:cpu].where(:device => @device, :index => @index).delete
    $LOG.info("Deleted cpu #{@index} (#{@description}) on #{@device}. Last poller: #{@worker}")

    return self
  end


  def to_json(*a)
    {
      "json_class" => self.class.name,
      "data" => {
        "device" => @device,
        "index" => @index,
        "util" => @util,
        "description" => @description,
        "last_updated" => @last_updated,
        "worker" => @worker,
      }
    }.to_json(*a)
  end


  def self.json_create(json)
    data = json["data"]
    CPU.new(device: data['device'], index: data['index']).populate(data)
  end


end
