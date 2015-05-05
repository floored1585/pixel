# component.rb
#
require 'logger'

$LOG ||= Logger.new(STDOUT)


class Component


  def self.fetch(device, index, hw_type)
    obj = API.get(
      src: 'component',
      dst: 'core',
      resource: "/v2/device/#{device}/#{hw_type}/#{index}",
      what: "#{hw_type} #{index} on #{device}",
    )
    obj.is_a?(Component) ? obj : nil
  end


  def initialize(device:, index:)
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
    @description || ''
  end


  def last_updated
    @last_updated || 0
  end


  def hw_type
    @hw_type
  end


  def populate(data)
    # Required in order to accept symbol and non-symbol keys
    data = data.symbolize

    # Return nil if we didn't find any data
    # TODO: Raise an exception instead?
    return nil if data.empty?

    @description = data[:description].to_s
    @last_updated = data[:last_updated].to_i_if_numeric
    @worker = data[:worker]

    return self
  end


  def update(data, worker:)
    new_description = data['description'] || "#{@hw_type} #{@index}"
    current_time = Time.now.to_i
    new_worker = worker

    @description = new_description
    @last_updated = current_time
    @worker = new_worker

    return self
  end


  def save(db)
    data = {}
    data[:device] = @device
    data[:hw_type] = @hw_type.downcase
    data[:index] = @index
    data[:description] = description
    data[:last_updated] = @last_updated if @last_updated
    data[:worker] = @worker if @worker

    # Update the component table
    existing = db[:component].where(:hw_type=>@hw_type.downcase, :device=>@device, :index=>@index)
    if existing.update(data) != 1
      $LOG.info("#{@hw_type}: Adding #{@index} (#{@description}) on #{@device} from #{@worker}")
      db[:component].insert(data)
    end

    return self
  end


  def delete(db)
    $LOG.info(
      "#{@hw_type}: Attempting to delete #{@index} (#{@description}) on #{@device}. " +
      "Last poller: #{@worker}"
    )

    db[:component].where(
      :hw_type => @hw_type.downcase,
      :device => @device,
      :index => @index
    ).delete
  end


  def to_json(*a)
    hash = {
      "json_class" => self.class.name,
      "data" => {}
    }

    hash['data']["device"] = @device
    hash['data']["index"] = @index
    hash['data']["description"] = description
    hash['data']["last_updated"] = @last_updated if @last_updated
    hash['data']["worker"] = @worker if @worker

    hash.to_json(*a)
  end


  def self.json_create(json)
    data = json["data"]
    Component.new(device: data['device'], index: data['index']).populate(data)
  end


end
