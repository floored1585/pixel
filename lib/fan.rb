# fan.rb
#
require 'logger'
require 'json'
require_relative 'api'
require_relative 'core_ext/object'
$LOG ||= Logger.new(STDOUT)

class Fan


  def self.fetch(device, index)
    obj = API.get('core', "/v2/device/#{device}/fan/#{index}", 'Fan', 'fan data')
    obj.class == Fan ? obj : nil
  end


  def initialize(device:, index:)

    # required
    @device = device
    @index = index.to_s

  end


  def device
    @device
  end


  def index
    @index
  end


  def description
    @description
  end


  def last_updated
    @last_updated || 0
  end


  def populate(data)

    # Required in order to accept symbol and non-symbol keys
    data = data.symbolize

    # Return nil if we didn't find any data
    # TODO: Raise an exception instead?
    return nil if data.empty?

    @description = data[:description]
    @last_updated = data[:last_updated].to_i_if_numeric
    @status = data[:status].to_i_if_numeric
    @vendor_status = data[:vendor_status].to_i_if_numeric
    @status_text = data[:status_text]
    @worker = data[:worker]

    return self
  end


  def update(data, worker:)

    # TODO: Data validation? See mac class for example

    new_description = data['description'] || "FAN #{@index}"
    current_time = Time.now.to_i
    new_status = data['status'].to_i_if_numeric
    new_vendor_status = data['vendor_status'].to_i_if_numeric
    new_status_text = data['status_text']
    new_worker = worker

    @description = new_description
    @last_updated = current_time
    @status = new_status
    @vendor_status = new_vendor_status
    @status_text = new_status_text
    @worker = new_worker

    return self
  end


  def save(db)
    data = JSON.parse(self.to_json)['data']

    # Update the fan table
    existing = db[:fan].where(:device => @device, :index => @index)
    if existing.update(data) != 1
      db[:fan].insert(data)
      $LOG.info("FAN: Adding new fan #{@index} on #{@device} from #{@worker}")
    end

    return self
  end


  def delete(db)
    # Delete the fan from the database
    count = db[:fan].where(:device => @device, :index => @index).delete
    $LOG.info("FAN: Deleted fan #{@index} (#{@description}) on #{@device}. Last poller: #{@worker}")

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

    hash['data']["description"] = @description if @description
    hash['data']["last_updated"] = @last_updated if @last_updated
    hash['data']["status"] = @status if @status
    hash['data']["vendor_status"] = @vendor_status if @vendor_status
    hash['data']["status_text"] = @status_text if @status_text
    hash['data']["worker"] = @worker if @worker

    hash.to_json(*a)
  end


  def self.json_create(json)
    data = json["data"]
    Fan.new(device: data['device'], index: data['index']).populate(data)
  end


end
