# memory.rb
#
require 'logger'
require 'json'
require_relative 'component'
require_relative 'core_ext/object'
$LOG ||= Logger.new(STDOUT)

class Memory < Component


  def self.fetch(device, index)
    obj = super(device, index, 'memory')
    obj.class == Memory ? obj : nil
  end


  def util
    @util || 0
  end


  def populate(data)
    # If parent's #populate returns nil, return nil here also
    return nil unless super

    # Required in order to accept symbol and non-symbol keys
    data = data.symbolize

    @util = data[:util].to_i

    return self
  end


  def update(data, worker:)

    # TODO: Data validation? See mac class for example

    super

    new_util = data['util'].to_i

    @util = new_util

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
    hash['data']["description"] = description
    hash['data']["last_updated"] = @last_updated if @last_updated
    hash['data']["worker"] = @worker if @worker

    hash.to_json(*a)
  end


  def self.json_create(json)
    data = json["data"]
    Memory.new(device: data['device'], index: data['index']).populate(data)
  end


end
