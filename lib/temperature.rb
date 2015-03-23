# temperature.rb
#
require 'json'

class Temperature


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
      @temperature = data['temperature'].to_i_if_numeric
      @last_updated = data['last_updated'].to_i_if_numeric
      @description = data['description']
      @status = data['status'].to_i_if_numeric
      @threshold = data['threshold'].to_i_if_numeric
      @vendor_status = data['vendor_status'].to_i_if_numeric
      @status_text = data['status_text']
    end

    return self
  end


  def update(data)

    new_temperature = data['temperature'].to_i_if_numeric
    current_time = Time.now.to_i
    new_description = data['description'] || "TEMP #{@index}"
    new_status = data['status'].to_i_if_numeric
    new_threshold = data['threshold'].to_i_if_numeric
    new_vendor_status = data['vendor_status'].to_i_if_numeric
    new_status_text = data['status_text']

    @temperature = new_temperature
    @last_updated = current_time
    @description = new_description
    @status = new_status
    @threshold = new_threshold
    @vendor_status = new_vendor_status
    @status_text = new_status_text

    return self
  end


  def to_json
    return "{}" unless @temperature && @last_updated && @description && @status && @status_text
    { "device" => @device,
      "index" => @index,
      "temperature" => @temperature,
      "last_updated" => @last_updated,
      "description" => @description,
      "status" => @status,
      "threshold" => @threshold,
      "vendor_status" => @vendor_status,
      "status_text" => @status_text,
    }.to_json
  end


end
