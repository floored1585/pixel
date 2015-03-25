# fan.rb
#
require 'json'

class Fan


  def initialize(device:, index:)

    # required
    @device = device
    @index = index

  end
  

  def populate(data={})

    # If we weren't passed data, look ourselves up
    if data.empty?
      return nil
      ## TODO ##
    else
      @description = data['description']
      @last_updated = data['last_updated'].to_i_if_numeric
      @status = data['status'].to_i_if_numeric
      @vendor_status = data['vendor_status'].to_i_if_numeric
      @status_text = data['status_text']
    end

    return self
  end


  def update(data)

    # TODO: Data validation? See mac class for example

    new_description = data['description'] || "FAN #{@index}"
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


  def to_json
    return "{}" unless @last_updated && @description && @status && @status_text
    { "device" => @device,
      "index" => @index,
      "description" => @description,
      "last_updated" => @last_updated,
      "status" => @status,
      "vendor_status" => @vendor_status,
      "status_text" => @status_text,
    }.to_json
  end


end
