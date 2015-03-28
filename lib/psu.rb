# psu.rb
#
require 'logger'
require 'json'
require_relative 'api'
require_relative 'core_ext/object'
$LOG ||= Logger.new(STDOUT)

class PSU


  def initialize(device:, index:)

    # required
    @device = device
    @index = index

  end
  

  def populate(data=nil)

    # If we weren't passed data, look ourselves up
    data ||= API.get('core', "/v1/device/#{@device}/psu/#{@index}", 'PSU', 'psu data')
    # Return nil if we didn't find any data
    # TODO: Raise an exception instead?
    return nil if data.empty?

    @description = data['description']
    @last_updated = data['last_updated'].to_i_if_numeric
    @status = data['status'].to_i_if_numeric
    @vendor_status = data['vendor_status'].to_i_if_numeric
    @status_text = data['status_text']

    return self
  end


  def update(data)

    # TODO: Data validation? See mac class for example

    new_description = data['description'] || "PSU #{@index}"
    current_time = Time.now.to_i
    new_status = data['status'].to_i_if_numeric
    new_vendor_status = data['vendor_status'].to_i_if_numeric
    new_status_text = data['status_text']

    @description = new_description
    @last_updated = current_time
    @status = new_status
    @vendor_status = new_vendor_status
    @status_text = new_status_text

    return self
  end


  def to_json(*a)
    { 
      "json_class" => self.class.name,
      "data" => {
        "device" => @device,
        "index" => @index,
        "description" => @description,
        "last_updated" => @last_updated,
        "status" => @status,
        "vendor_status" => @vendor_status,
        "status_text" => @status_text,
      }
    }.to_json(*a)
  end


  def self.json_create(json)
    data = json["data"]
    PSU.new(device: data['device'], index: data['index']).populate(data)
  end


end
