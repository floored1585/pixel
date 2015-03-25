# memory.rb
#
require 'json'

class Memory


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
      @util = data['util'].to_i
      @description = data['description']
      @last_updated = data['last_updated'].to_i
    end

    return self
  end


  def update(data)

    # TODO: Data validation? See mac class for example

    new_util = data['util'].to_i
    new_description = data['description'] || "Memory #{@index}"
    current_time = Time.now.to_i

    @util = new_util
    @description = new_description
    @last_updated = current_time

    return self
  end


  def to_json
    return "{}" unless @util && @description && @last_updated
    { "device" => @device,
      "index" => @index,
      "util" => @util,
      "description" => @description,
      "last_updated" => @last_updated,
    }.to_json
  end


end
