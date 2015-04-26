# memory.rb
#
require 'logger'
require 'json'
require_relative 'api'
require_relative 'core_ext/object'
$LOG ||= Logger.new(STDOUT)

class Memory


  def self.fetch(device, index)
    obj = API.get(
      src: 'memory',
      dst: 'core',
      resource: "/v2/device/#{device}/memory/#{index}",
      what: "memory #{index} on #{device}",
    )
    obj.class == Memory ? obj : nil
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


  def util
    @util || 0
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

    @util = data[:util].to_i
    @description = data[:description]
    @last_updated = data[:last_updated].to_i_if_numeric
    @worker = data[:worker]

    return self
  end


  def update(data, worker:)

    # TODO: Data validation? See mac class for example

    new_util = data['util'].to_i
    new_description = data['description'] || "Memory #{@index}"
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
      series: "#{@device}.memory.#{@index}.#{@description}",
      value: @util,
      time: @last_updated,
    )
  end


  def save(db)
    data = JSON.parse(self.to_json)['data']

    # Update the memory table
    begin
      existing = db[:memory].where(:device => @device, :index => @index)
      if existing.update(data) != 1
        db[:memory].insert(data)
        $LOG.info("MEMORY: Adding new memory #{@index} on #{@device} from #{@worker}")
      end
    rescue Sequel::NotNullConstraintViolation, Sequel::ForeignKeyConstraintViolation => e
      $LOG.error("MEMORY: Save failed. #{e.to_s.gsub(/\n/,'. ')}")
      return nil
    end

    return self
  end


  def delete(db)
    # Delete the memory from the database
    count = db[:memory].where(:device => @device, :index => @index).delete
    $LOG.info("MEMORY: Deleted memory #{@index} (#{@description}) on #{@device}. Last poller: #{@worker}")

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

    hash['data']["util"] = util
    hash['data']["description"] = @description if @description
    hash['data']["last_updated"] = @last_updated if @last_updated
    hash['data']["worker"] = @worker if @worker

    hash.to_json(*a)
  end


  def self.json_create(json)
    data = json["data"]
    Memory.new(device: data['device'], index: data['index']).populate(data)
  end


end
