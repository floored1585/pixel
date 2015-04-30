# psu.rb
#
require 'logger'
require 'json'
require_relative 'component'
require_relative 'core_ext/object'
$LOG ||= Logger.new(STDOUT)

class PSU < Component


  def self.fetch(device, index)
    obj = super(device, index, 'psu')
    obj.class == PSU ? obj : nil
  end


  def status_text
    @status_text
  end


  def populate(data)
    # If parent's #populate returns nil, return nil here also
    return nil unless super

    # Required in order to accept symbol and non-symbol keys
    data = data.symbolize

    @status = data[:status].to_i_if_numeric
    @vendor_status = data[:vendor_status].to_i_if_numeric
    @status_text = data[:status_text]

    return self
  end


  def update(data, worker:)

    # TODO: Data validation? See mac class for example

    super

    new_status = data['status'].to_i_if_numeric
    new_vendor_status = data['vendor_status'].to_i_if_numeric
    new_status_text = data['status_text']

    @status = new_status
    @vendor_status = new_vendor_status
    @status_text = new_status_text

    return self
  end


  def save(db)
    data = JSON.parse(self.to_json)['data']

    # Update the psu table
    begin
      existing = db[:psu].where(:device => @device, :index => @index)
      if existing.update(data) != 1
        db[:psu].insert(data)
        $LOG.info("PSU: Adding new psu #{@index} on #{@device} from #{@worker}")
      end
    rescue Sequel::NotNullConstraintViolation, Sequel::ForeignKeyConstraintViolation => e
      $LOG.error("PSU: Save failed. #{e.to_s.gsub(/\n/,'. ')}")
      return nil
    end

    return self
  end


  def delete(db)
    # Delete the psu from the database
    count = db[:psu].where(:device => @device, :index => @index).delete
    $LOG.info("PSU: Deleted psu #{@index} (#{@description}) on #{@device}. Last poller: #{@worker}")

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

    hash['data']["description"] = description
    hash['data']["last_updated"] = @last_updated if @last_updated
    hash['data']["status"] = @status if @status
    hash['data']["vendor_status"] = @vendor_status if @vendor_status
    hash['data']["status_text"] = @status_text if @status_text
    hash['data']["worker"] = @worker if @worker

    hash.to_json(*a)
  end


  def self.json_create(json)
    data = json["data"]
    PSU.new(device: data['device'], index: data['index']).populate(data)
  end


end
