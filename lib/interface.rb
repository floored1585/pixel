# interface.rb
#
require 'logger'
require 'json'
require_relative 'component'
require_relative 'core_ext/object'
$LOG ||= Logger.new(STDOUT)

class Interface < Component


  def self.fetch(device, index)
    obj = super(device, index, 'interface')
    obj.class == Interface ? obj : nil
  end


  def initialize(device:, index:)
    # If index doesn't look like an integer, raise an exception.
    unless index.to_s =~ /^[0-9]+$/
      raise TypeError.new("index (#{index}) must look like an Integer!")
    end

    super(device: device, index: index, hw_type: 'Interface')
  end


  def speed
    @speed
  end


  def set_speed(speed)
    # If speed doesn't look like an integer, raise an exception.
    unless speed.to_s =~ /^[0-9]+$/
      raise TypeError.new("speed (#{speed}) must look like an Integer!")
    end

    @speed = speed.to_i

    return self
  end


  def name
    @name
  end


  def type
    return "Access" if @type == 'acc'
    return "Backbone" if @type == 'bb'
    return "Unknown" if @type == 'unknown'
  end


  def type_raw
    @type
  end


  def oper_status_time
    @oper_status_time
  end


  def bps_in
    @bps_in || 0
  end


  def bps_out
    @bps_out || 0
  end


  def pps_in
    @pps_in || 0
  end


  def pps_out
    @pps_out || 0
  end


  def discards_in
    @discards_in || 0
  end


  def discards_out
    @discards_out || 0
  end


  def discards_out_pct
    if discards_out && pps_out && discards_out > 0
      return ('%.2f' % (discards_out.to_f / (pps_out + discards_out) * 100)).to_f
    end
    return 0.0
  end


  def errors_in
    @errors_in || 0
  end


  def errors_out
    @errors_out || 0
  end


  def bps_util_in
    _calculate_utilization(@bps_in)
  end


  def bps_util_out
    _calculate_utilization(@bps_out)
  end


  # Returns true unless the interface is name looks logical.  Also returns
  #   true if @name is nil.
  def physical?
    @name !~ /Po|ae|bond/
  end


  def child?
    !!(@description =~ /^sub\[/)
  end


  def parent_name
    return nil unless child?
    @description.match(/sub\[([a-zA-Z0-9\/-]+)\]/) { |match| return match[1] }
  end


  def neighbor
    return nil unless @description
    @description.match(/__([a-zA-Z0-9\-_]+)__/) { |match| return match[1] }
  end


  def neighbor_port
    return nil unless @description
    @description.match(/__([0-9a-zA-Z\-.: \/]+)$/) { |match| return match[1] }
  end


  # Returns a text representation of the up/down interface status (by default, the
  #   operating status, but you can pass in a symbol if you want to get the admin status)
  def status(status_type = :oper)
    if status_type == :oper
      @oper_status == 1 ? "Up" : "Down"
    elsif status_type == :admin
      @admin_status == 1 ? "Up" : "Down"
    else
      nil
    end
  end


  def up?
    status == 'Up'
  end


  def down?
    status == 'Down'
  end


  def stale?(timer: 600)
    time_since_update = Time.now.to_i - @last_updated
    return time_since_update if time_since_update > timer
    return false
  end


  # Substitutes characters in the current name using the provided hash
  def substitute_name(substitutions)

    # If @name hasn't been set, return nil (we can't gsub what doesn't exist)
    return nil unless @name

    @name.gsub!(Regexp.new(substitutions.keys.join('|')), substitutions)
    return @name
  end


  # This method takes an interface, and mimics its type (sets this interface's
  #   type to be the same as the interface that was passed in)
  def clone_type(int)
    @type = int.type_raw unless int.type_raw == nil
    return self
  end


  def populate(data)
    # If parent's #populate returns nil, return nil here also
    return nil unless super

    # Required in order to accept symbol and non-symbol keys
    data = data.symbolize

    @name = data[:name]
    @hc_in_octets = data[:hc_in_octets].to_i_if_numeric
    @hc_out_octets = data[:hc_out_octets].to_i_if_numeric
    @hc_in_ucast_pkts = data[:hc_in_ucast_pkts].to_i_if_numeric
    @hc_out_ucast_pkts = data[:hc_out_ucast_pkts].to_i_if_numeric
    @speed = data[:speed].to_i_if_numeric
    @mtu = data[:mtu].to_i_if_numeric
    @admin_status = data[:admin_status].to_i_if_numeric
    @admin_status_time = data[:admin_status_time].to_i_if_numeric
    @oper_status = data[:oper_status].to_i_if_numeric
    @oper_status_time = data[:oper_status_time].to_i_if_numeric
    @in_discards = data[:in_discards].to_i_if_numeric
    @in_errors = data[:in_errors].to_i_if_numeric
    @out_discards = data[:out_discards].to_i_if_numeric
    @out_errors = data[:out_errors].to_i_if_numeric
    @bps_in = data[:bps_in].to_i_if_numeric
    @bps_out = data[:bps_out].to_i_if_numeric
    @discards_in = data[:discards_in].to_i_if_numeric
    @errors_in = data[:errors_in].to_i_if_numeric
    @discards_out = data[:discards_out].to_i_if_numeric
    @errors_out = data[:errors_out].to_i_if_numeric
    @pps_in = data[:pps_in].to_i_if_numeric
    @pps_out = data[:pps_out].to_i_if_numeric
    @type = data[:type]

    return self

  end


  def update(data, worker:)
    # Save times (@last_updated gets modified by super)
    old_time = @last_updated
    old_description = @description
    current_time = Time.now.to_i

    super

    # Save the data we need for deltas as new variables
    new_name = data['name']
    new_hc_in_octets = data['hc_in_octets'].to_i_if_numeric
    new_hc_out_octets = data['hc_out_octets'].to_i_if_numeric
    new_hc_in_ucast_pkts = data['hc_in_ucast_pkts'].to_i_if_numeric
    new_hc_out_ucast_pkts = data['hc_out_ucast_pkts'].to_i_if_numeric
    new_speed = data['high_speed'].to_i_if_numeric * 1000000
    new_mtu = data['mtu'].to_i_if_numeric
    new_admin_status = data['admin_status'].to_i_if_numeric
    new_oper_status = data['oper_status'].to_i_if_numeric
    new_in_discards = data['in_discards'].to_i_if_numeric
    new_in_errors = data['in_errors'].to_i_if_numeric
    new_out_discards = data['out_discards'].to_i_if_numeric
    new_out_errors = data['out_errors'].to_i_if_numeric


    # Generate events if things have changed
    #
    @events ||= []

    # Description change
    if @description != old_description
      @events.push(DescriptionChangeEvent.new(
        device: @device, hw_type: @hw_type, index: @index,
        old: old_description, new: @description
      ))
    end


    # Determine interface type, by capturing the part of the description before __ or [
    if type_match = @description.match(/^([a-z]+)(?:__|\[)/)
      @type = type_match[1]
    else
      @type = 'unknown'
    end

    # Calcaulate the deltas
    if old_time
      @bps_in = _calculate_average(
        old_time: old_time, old_value: @hc_in_octets * 8,
        new_time: current_time, new_value: new_hc_in_octets * 8
      )
      @bps_out = _calculate_average(
        old_time: old_time, old_value: @hc_out_octets * 8,
        new_time: current_time, new_value: new_hc_out_octets * 8
      )
      @pps_in = _calculate_average(
        old_time: old_time, old_value: @hc_in_ucast_pkts,
        new_time: current_time, new_value: new_hc_in_ucast_pkts
      )
      @pps_out = _calculate_average(
        old_time: old_time, old_value: @hc_out_ucast_pkts,
        new_time: current_time, new_value: new_hc_out_ucast_pkts
      )
      @discards_in = _calculate_average(
        old_time: old_time, old_value: @in_discards,
        new_time: current_time, new_value: new_in_discards
      )
      @discards_out = _calculate_average(
        old_time: old_time, old_value: @out_discards,
        new_time: current_time, new_value: new_out_discards
      )
      @errors_in = _calculate_average(
        old_time: old_time, old_value: @in_errors,
        new_time: current_time, new_value: new_in_errors
      )
      @errors_out = _calculate_average(
        old_time: old_time, old_value: @out_errors,
        new_time: current_time, new_value: new_out_errors
      )
    end

    # If the admin or oper statuses are changing, update their timestamps
    @admin_status_time = current_time if @admin_status != new_admin_status
    @oper_status_time = current_time if @oper_status != new_oper_status

    # Lastly, update all the non-calculated instance variables
    @name = new_name
    @hc_in_octets = new_hc_in_octets
    @hc_out_octets = new_hc_out_octets
    @hc_in_ucast_pkts = new_hc_in_ucast_pkts
    @hc_out_ucast_pkts = new_hc_out_ucast_pkts
    @speed = new_speed
    @mtu = new_mtu
    @admin_status = new_admin_status
    @oper_status = new_oper_status
    @in_discards = new_in_discards
    @in_errors = new_in_errors
    @out_discards = new_out_discards
    @out_errors = new_out_errors

    return self

  end


  def write_influxdb
    Influx.post(
      series: "#{@device}.interface.#{@index}.#{@name}.bps_in",
      value: bps_in,
      time: @last_updated,
    )
    Influx.post(
      series: "#{@device}.interface.#{@index}.#{@name}.bps_out",
      value: bps_out,
      time: @last_updated,
    )
    Influx.post(
      series: "#{@device}.interface.#{@index}.#{@name}.pps_in",
      value: pps_in,
      time: @last_updated,
    )
    Influx.post(
      series: "#{@device}.interface.#{@index}.#{@name}.pps_out",
      value: pps_out,
      time: @last_updated,
    )
    Influx.post(
      series: "#{@device}.interface.#{@index}.#{@name}.discards_in",
      value: discards_in,
      time: @last_updated,
    )
    Influx.post(
      series: "#{@device}.interface.#{@index}.#{@name}.discards_out",
      value: discards_out,
      time: @last_updated,
    )
    Influx.post(
      series: "#{@device}.interface.#{@index}.#{@name}.errors_in",
      value: errors_in,
      time: @last_updated,
    )
    Influx.post(
      series: "#{@device}.interface.#{@index}.#{@name}.errors_out",
      value: errors_out,
      time: @last_updated,
    )
    Influx.post(
      series: "#{@device}.interface.#{@index}.#{@name}.bps_util_in",
      value: bps_util_in,
      time: @last_updated,
    )
    Influx.post(
      series: "#{@device}.interface.#{@index}.#{@name}.bps_util_out",
      value: bps_util_out,
      time: @last_updated,
    )
  end


  def save(db)
    begin
      super # Component#save

      data = { :id => @id }
      data[:name] = @name if @name
      data[:hc_in_octets] = @hc_in_octets if @hc_in_octets
      data[:hc_out_octets] = @hc_out_octets if @hc_out_octets
      data[:hc_in_ucast_pkts] = @hc_in_ucast_pkts if @hc_in_ucast_pkts
      data[:hc_out_ucast_pkts] = @hc_out_ucast_pkts if @hc_out_ucast_pkts
      data[:speed] = @speed if @speed
      data[:mtu] = @mtu if @mtu
      data[:admin_status] = @admin_status if @admin_status
      data[:admin_status_time] = @admin_status_time if @admin_status_time
      data[:oper_status] = @oper_status if @oper_status
      data[:oper_status_time] = @oper_status_time if @oper_status_time
      data[:in_discards] = @in_discards if @in_discards
      data[:in_errors] = @in_errors if @in_errors
      data[:out_discards] = @out_discards if @out_discards
      data[:out_errors] = @out_errors if @out_errors
      data[:bps_in] = @bps_in if @bps_in
      data[:bps_out] = @bps_out if @bps_out
      data[:discards_in] = @discards_in if @discards_in
      data[:errors_in] = @errors_in if @errors_in
      data[:discards_out] = @discards_out if @discards_out
      data[:errors_out] = @errors_out if @errors_out
      data[:pps_in] = @pps_in if @pps_in
      data[:pps_out] = @pps_out if @pps_out
      data[:bps_util_in] = bps_util_in
      data[:bps_util_out] = bps_util_out
      data[:type] = @type if @type

      existing = db[:interface].where(:id => @id)
      if existing.update(data) != 1
        db[:interface].insert(data)
      end
    rescue Sequel::NotNullConstraintViolation, Sequel::ForeignKeyConstraintViolation => e
      $LOG.error("INTERFACE: Save failed. #{e.to_s.gsub(/\n/,'. ')}")
      return nil
    end

    return self
  end


  def to_json(*a)
    hash = {
      "json_class" => self.class.name,
      "data" => {}
    }

    hash['data']["name"] = @name if @name
    hash['data']["hc_in_octets"] = @hc_in_octets if @hc_in_octets
    hash['data']["hc_out_octets"] = @hc_out_octets if @hc_out_octets
    hash['data']["hc_in_ucast_pkts"] = @hc_in_ucast_pkts if @hc_in_ucast_pkts
    hash['data']["hc_out_ucast_pkts"] = @hc_out_ucast_pkts if @hc_out_ucast_pkts
    hash['data']["speed"] = @speed if @speed
    hash['data']["mtu"] = @mtu if @mtu
    hash['data']["admin_status"] = @admin_status if @admin_status
    hash['data']["admin_status_time"] = @admin_status_time if @admin_status_time
    hash['data']["oper_status"] = @oper_status if @oper_status
    hash['data']["oper_status_time"] = @oper_status_time if @oper_status_time
    hash['data']["in_discards"] = @in_discards if @in_discards
    hash['data']["in_errors"] = @in_errors if @in_errors
    hash['data']["out_discards"] = @out_discards if @out_discards
    hash['data']["out_errors"] = @out_errors if @out_errors
    hash['data']["bps_in"] = @bps_in if @bps_in
    hash['data']["bps_out"] = @bps_out if @bps_out
    hash['data']["discards_in"] = @discards_in if @discards_in
    hash['data']["errors_in"] = @errors_in if @errors_in
    hash['data']["discards_out"] = @discards_out if @discards_out
    hash['data']["errors_out"] = @errors_out if @errors_out
    hash['data']["pps_in"] = @pps_in if @pps_in
    hash['data']["pps_out"] = @pps_out if @pps_out
    hash['data']["bps_util_in"] = bps_util_in
    hash['data']["bps_util_out"] = bps_util_out
    hash['data']["type"] = @type if @type
    hash['data'].merge!( JSON.parse(super)['data'] )

    hash.to_json(*a)
  end


  def self.json_create(json)
    data = json["data"]
    Interface.new(device: data['device'], index: data['index']).populate(data)
  end


  private # All methods below are private!!


  # PRIVATE!
  def _calculate_average(old_time:, old_value:, new_time:, new_value:)
    # If we don't have an old time and value (first poll, for example), return nil
    return nil unless old_time && old_value
    return (new_value - old_value) / (new_time - old_time)
  end


  # PRIVATE!
  def _calculate_utilization(bps)
    if bps && @speed && @speed != 0
      util = ('%.2f' % (bps.to_f / (@speed) * 100)).to_f
    else
      util = 0.0
    end

    # Cap utilization at 100.  Necessary??
    util = 100.0 if util > 100
    return util
  end


end
