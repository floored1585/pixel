# temperature.rb
#
require 'logger'
require 'json'
require_relative 'api'
require_relative 'core_ext/object'
$LOG ||= Logger.new(STDOUT)

class Temperature


  def initialize(device:, index:)

    # required
    @device = device
    @index = index

  end
  

  def last_updated
    @last_updated || 0
  end


  def populate(data=nil)

    # If we weren't passed data, look ourselves up
    data ||= API.get('core', "/v2/device/#{@device}/temperature/#{@index}", 'Temperature', 'temperature data')
    # Return nil if we didn't find any data
    # TODO: Raise an exception instead?
    return nil if data.empty?

    @temperature = data['temperature'].to_i_if_numeric
    @last_updated = data['last_updated'].to_i_if_numeric
    @description = data['description']
    @status = data['status'].to_i_if_numeric
    @threshold = data['threshold'].to_i_if_numeric
    @vendor_status = data['vendor_status'].to_i_if_numeric
    @status_text = data['status_text']
    @worker = data['worker']

    return self
  end


  def update(data, worker:)

    # TODO: Data validation? See mac class for example

    new_temperature = data['temperature'].to_i_if_numeric
    current_time = Time.now.to_i
    new_description = data['description'] || "TEMP #{@index}"
    new_status = data['status'].to_i_if_numeric
    new_threshold = data['threshold'].to_i_if_numeric
    new_vendor_status = data['vendor_status'].to_i_if_numeric
    new_status_text = data['status_text']
    new_worker = worker

    @temperature = new_temperature
    @last_updated = current_time
    @description = new_description
    @status = new_status
    @threshold = new_threshold
    @vendor_status = new_vendor_status
    @status_text = new_status_text
    @worker = new_worker

    return self
  end


  def write_influxdb
    Influx.post(
      series: "#{@name}.temperature.#{@index}.#{@description}",
      value: @temperature,
      time: @last_updated,
    )
  end


  def save(db)
    data = JSON.parse(self.to_json)['data']

    # Update the temperature table
    existing = db[:temperature].where(:device => @device, :index => @index)
    if existing.update(data) != 1
      db[:temperature].insert(data)
      $LOG.info("Adding new temperature #{@index} on #{@device} from #{@worker}")
    end

    return self
  end


  def delete(db)
    # Delete the temperature from the database
    count = db[:temperature].where(:device => @device, :index => @index).delete
    $LOG.info("Deleted temperature #{@index} (#{@description}) on #{@device}. Last poller: #{@worker}")

    return count
  end


  def to_json(*a)
    hash = {
      "json_class" => self.class.name,
      "data" => {
        "device" => @device,
        "index" => @index,
      }
    }

    hash['data']["temperature"] = @temperature if @temperature
    hash['data']["last_updated"] = @last_updated if @last_updated
    hash['data']["description"] = @description if @description
    hash['data']["status"] = @status if @status
    hash['data']["threshold"] = @threshold if @threshold
    hash['data']["vendor_status"] = @vendor_status if @vendor_status
    hash['data']["status_text"] = @status_text if @status_text
    hash['data']["worker"] = @worker if @worker

    hash.to_json(*a)
  end


  def self.json_create(json)
    data = json["data"]
    Temperature.new(device: data['device'], index: data['index']).populate(data)
  end


end
