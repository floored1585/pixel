# interface.rb
#
# TODO: @type must be calculated in device.rb somewhere
#

class Interface


  def initialize(device:, index:)

    # If index doesn't look like an integer, raise an exception.
    unless index.to_s =~ /^[0-9]+$/
      raise TypeError.new("index (#{index}) must look like an Integer!") 
    end

    # required
    @device = device
    @index = index.to_i

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

    # Re-calculate utilization, since the speed has changed
    _calculate_utilization

    return self
  end


  def name
    @name
  end


  # Substitutes characters in the current name using the provided hash
  def substitute_name(substitutions)

    # If @name hasn't been set, return nil (we can't gsub what doesn't exist)
    return nil unless @name

    @name.gsub!(Regexp.new(substitutions.keys.join('|')), substitutions)
    return @name
  end


  def alias
    @alias
  end


  def type
    @type
  end


  # This method takes an interface, and mimics its type (sets this interface's
  #   type to be the same as the interface that was passed in)
  def clone_type(int)
    @type = int.type unless int.type == nil
    return self
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


  def bps_in
    @bps_in || 0.0
  end
  def bps_out
    @bps_out || 0.0
  end


  def bps_in_util
    @bps_in_util || 0.0
  end
  def bps_out_util
    @bps_out_util || 0.0
  end


  def populate(data={})

    # If we weren't passed data, look ourselves up
    if data.empty?
      return nil
      ## TODO ##
    else
      @last_updated = data['last_updated'].to_i_if_numeric
      @alias = data['if_alias']
      @name = data['if_name']
      @hc_in_octets = data['if_hc_in_octets'].to_i_if_numeric
      @hc_out_octets = data['if_hc_out_octets'].to_i_if_numeric
      @hc_in_ucast_pkts = data['if_hc_in_ucast_pkts'].to_i_if_numeric
      @hc_out_ucast_pkts = data['if_hc_out_ucast_pkts'].to_i_if_numeric
      @speed = data['if_speed'].to_i_if_numeric
      @mtu = data['if_mtu'].to_i_if_numeric
      @admin_status = data['if_admin_status'].to_i_if_numeric
      @admin_status_time = data['if_admin_status_time'].to_i_if_numeric
      @oper_status = data['if_oper_status'].to_i_if_numeric
      @oper_status_time = data['if_oper_status_time'].to_i_if_numeric
      @in_discards = data['if_in_discards'].to_i_if_numeric
      @in_errors = data['if_in_errors'].to_i_if_numeric
      @out_discards = data['if_out_discards'].to_i_if_numeric
      @out_errors = data['if_out_errors'].to_i_if_numeric
      @bps_in = data['bps_in'].to_i_if_numeric
      @bps_out = data['bps_out'].to_i_if_numeric
      @discards_in = data['discards_in'].to_i_if_numeric
      @errors_in = data['errors_in'].to_i_if_numeric
      @discards_out = data['discards_out'].to_i_if_numeric
      @errors_out = data['errors_out'].to_i_if_numeric
      @pps_in = data['pps_in'].to_i_if_numeric
      @pps_out = data['pps_out'].to_i_if_numeric
      @bps_in_util = data['bps_in_util'].to_f
      @bps_out_util = data['bps_out_util'].to_f
      @type = data['if_type']

      return self
    end

  end


  def update(data)
    # Save the data we need for deltas as new variables
    current_time = Time.now.to_i
    new_name = data['if_name']
    new_hc_in_octets = data['if_hc_in_octets'].to_i_if_numeric
    new_hc_out_octets = data['if_hc_out_octets'].to_i_if_numeric
    new_hc_in_ucast_pkts = data['if_hc_in_ucast_pkts'].to_i_if_numeric
    new_hc_out_ucast_pkts = data['if_hc_out_ucast_pkts'].to_i_if_numeric
    new_speed = data['if_high_speed'].to_i_if_numeric * 1000000
    new_alias = data['if_alias']
    new_mtu = data['if_mtu'].to_i_if_numeric
    new_admin_status = data['if_admin_status'].to_i_if_numeric
    new_oper_status = data['if_oper_status'].to_i_if_numeric
    new_in_discards = data['if_in_discards'].to_i_if_numeric
    new_in_errors = data['if_in_errors'].to_i_if_numeric
    new_out_discards = data['if_out_discards'].to_i_if_numeric
    new_out_errors = data['if_out_errors'].to_i_if_numeric

    # Determine interface type, by capturing the part of the alias before __ or [
    if type_match = new_alias.match(/^([a-z]+)(?:__|\[)/)
      @type = type_match[1]
    else
      @type = 'unknown'
    end

    # Calcaulate the deltas
    if @last_updated
      @bps_in = _calculate_average(
        old_time: @last_updated, old_value: @hc_in_octets * 8,
        new_time: current_time, new_value: new_hc_in_octets * 8
      )
      @bps_out = _calculate_average(
        old_time: @last_updated, old_value: @hc_out_octets * 8,
        new_time: current_time, new_value: new_hc_out_octets * 8
      )
      @pps_in = _calculate_average(
        old_time: @last_updated, old_value: @hc_in_ucast_pkts,
        new_time: current_time, new_value: new_hc_in_ucast_pkts
      )
      @pps_out = _calculate_average(
        old_time: @last_updated, old_value: @hc_out_ucast_pkts,
        new_time: current_time, new_value: new_hc_out_ucast_pkts
      )
      @discards_in = _calculate_average(
        old_time: @last_updated, old_value: @hc_in_discards,
        new_time: current_time, new_value: new_in_discards
      )
      @discards_out = _calculate_average(
        old_time: @last_updated, old_value: @hc_out_discards,
        new_time: current_time, new_value: new_out_discards
      )
      @errors_in = _calculate_average(
        old_time: @last_updated, old_value: @in_errors,
        new_time: current_time, new_value: new_in_errors
      )
      @errors_out = _calculate_average(
        old_time: @last_updated, old_value: @out_errors,
        new_time: current_time, new_value: new_out_errors
      )
    end

    # If the admin or oper statuses are changing, update their timestamps
    @admin_status_time = Time.now.to_i if @admin_status != new_admin_status
    @oper_status_time = Time.now.to_i if @oper_status != new_oper_status

    # Lastly, update all the non-calculated instance variables
    @last_updated = current_time
    @name = new_name
    @hc_in_octets = new_hc_in_octets
    @hc_out_octets = new_hc_out_octets
    @hc_in_ucast_pkts = new_hc_in_ucast_pkts
    @hc_out_ucast_pkts = new_hc_out_ucast_pkts
    @speed = new_speed
    @alias = new_alias
    @mtu = new_mtu
    @admin_status = new_admin_status
    @oper_status = new_oper_status
    @in_discards = new_in_discards
    @in_errors = new_in_errors
    @out_discards = new_out_discards
    @out_errors = new_out_errors

    _calculate_utilization

    return self

  end


  def write_to_influxdb
    #TODO
  end


  private # All methods below are private!!

  # PRIVATE!
  def _calculate_average(old_time:, old_value:, new_time:, new_value:)
    # If we don't have an old time and value (first poll, for example), return nil
    return nil unless old_time && old_value
    return (new_value - old_value) / (new_time - old_time)
  end


  # PRIVATE!
  def _calculate_utilization

    if @speed == nil || @speed == 0
      @bps_in_util = 0.0
      @bps_out_util = 0.0
    else
      @bps_in_util = ('%.2f' % (@bps_in.to_f / (@speed) * 100)).to_f if @bps_in
      @bps_out_util = ('%.2f' % (@bps_out.to_f / (@speed) * 100)).to_f if @bps_out
    end

    # Cap utilization at 100.  Necessary??
    @bps_in_util = 100.0 if @bps_in_util && @bps_in_util > 100
    @bps_out_util = 100.0 if @bps_out_util && @bps_out_util > 100

  end


end
