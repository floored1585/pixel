# cpu.rb
#
require 'logger'
require 'json'
require_relative 'component'
require_relative 'core_ext/object'
$LOG ||= Logger.new(STDOUT)

class CPU < Component


  def self.fetch(device, index)
    obj = super(device, index, 'cpu')
    obj.class == CPU ? obj : nil
  end


  def util
    @util || 0
  end


  def populate(data)
    # If parent's #populate returns nil, return nil here also
    return nil unless super

    # Required in order to accept symbol and non-symbol keys
    data = data.symbolize

    @util = data[:util].to_i_if_numeric

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
      series: "#{@device}.cpu.#{@index}.#{@description}",
      value: @util,
      time: @last_updated,
    )
  end


  def save(db)
    data = JSON.parse(self.to_json)['data']

    # Update the cpu table
    begin
      existing = db[:cpu].where(:device => @device, :index => @index)
      if existing.update(data) != 1
        db[:cpu].insert(data)
        $LOG.info("CPU: Adding new cpu #{@index} on #{@device} from #{@worker}")
      end
    rescue Sequel::NotNullConstraintViolation, Sequel::ForeignKeyConstraintViolation => e
      $LOG.error("CPU: Save failed. #{e.to_s.gsub(/\n/,'. ')}")
      return nil
    end

    return self
  end


  def delete(db)
    # Delete the cpu from the database
    count = db[:cpu].where(:device => @device, :index => @index).delete
    $LOG.info("CPU: Deleted cpu #{@index} (#{@description}) on #{@device}. Last poller: #{@worker}")

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
    CPU.new(device: data['device'], index: data['index']).populate(data)
  end


end
