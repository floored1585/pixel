# fan.rb
#
require 'logger'
require 'json'
require_relative 'component'
require_relative 'core_ext/object'
$LOG ||= Logger.new(STDOUT)

class Fan < Component


  def self.fetch(device, index)
    obj = super(device, index, 'fan')
    obj.class == Fan ? obj : nil
  end


  def initialize(device:, index:)
    super
    @hw_type = 'Fan'
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
    begin
      super # Component#save

      data = { :id => @id }
      data[:status] = @status if @status
      data[:vendor_status] = @vendor_status if @vendor_status
      data[:status_text] = @status_text if @status_text

      existing = db[:fan].where(:id => @id)
      if existing.update(data) != 1
        db[:fan].insert(data)
      end
    rescue Sequel::NotNullConstraintViolation, Sequel::ForeignKeyConstraintViolation => e
      $LOG.error("FAN: Save failed. #{e.to_s.gsub(/\n/,'. ')}")
      return nil
    end

    return self
  end


  def to_json(*a)
    hash = {
      "json_class" => self.class.name,
      "data" => {
        "device" => @device,
        "index" => @index,
      }
    }

    hash['data']["status"] = @status if @status
    hash['data']["vendor_status"] = @vendor_status if @vendor_status
    hash['data']["status_text"] = @status_text if @status_text
    hash['data'].merge!( JSON.parse(super)['data'] )

    hash.to_json(*a)
  end


  def self.json_create(json)
    data = json["data"]
    Fan.new(device: data['device'], index: data['index']).populate(data)
  end


end
