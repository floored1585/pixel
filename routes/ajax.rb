#
# Pixel is an open source network monitoring system
# Copyright (C) 2016 all Pixel contributors!
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Pixel < Sinatra::Base


  #
  # GETS
  #
  get '/ajax/events/type' do
    JSON.generate Event.get_types(@@db)
  end


  get '/ajax/events' do
    start_time = params[:start_time].to_i_if_numeric
    end_time = params[:end_time].to_i_if_numeric
    limit = params[:limit] || 100 # return a max of 100 results
    meta_only = params[:meta_only]
    device = params[:device]
    device_partial = params[:device_partial]
    hw_type = params[:hw_type]
    types = params[:type] ? params[:type].split('$') : nil

    data = {}
    data['meta'] = {
      '_th_' => {
        'pxl-sort' => true
      },
      '_filters_' => [
        'device',
        'device_partial',
        'start_time',
        'end_time',
        'hw_type',
        'type',
        'limit',
      ],
      '_dropdowns_' => {
        'type' => {
          'url' => '/ajax/events/type',
          'placeholder' => 'Select event types to display',
        },
      },
    }
    data['data'] = []

    return JSON.generate(data) if limit.to_i < 1 || meta_only

    events = ComponentEvent.fetch_from_db(
      start_time: start_time, end_time: end_time, types: types, db: @@db, limit: limit,
      device: device, hw_type: hw_type, device_partial: device_partial
    )

    events.each do |event|
      temp = JSON.parse(event.to_json)['data']
      component = Component.fetch_from_db(id: event.component_id, db: @@db).first
      # Create the details field as appropriate for the event
      temp['details'] = event.html_details(component)
      temp['friendly_subtype'] = event.class.friendly_subtype
      temp['rawtime'] = temp['time']
      temp.merge!(JSON.parse(component.to_json)['data'])
      # make the device a link instead of raw device name
      temp['device'] = device_link(temp['device'])
      data['data'].push(temp)
    end
    return JSON.generate(data)

  end


  get '/ajax/interfaces' do
    limit = params[:limit] || 100 # return a max of 100 results
    meta_only = params[:meta_only]
    device_name = params[:device]
    device_partial = params[:device_partial]

    data = {}
    data['meta'] = {
      '_th_' => {
        'pxl-sort' => true
      },
      '_filters_' => [
        'device',
        'device_partial',
        'limit',
      ],
      '_dropdowns_' => {
      },
    }
    data['data'] = []

    return JSON.generate(data) if limit.to_i < 1 || meta_only

    ints = Component.fetch_from_db(
      hw_types: ['Interface'], db: @@db, limit: limit, device: device_name, device_partial: device_partial
    )

    devices = {}
    valid_children = {}

    # Convert the array of ints to a hash with unique keys
    ints = ints.map { |int| ["#{int.device}_#{int.index}", int] }.to_h

    ints.dup.each do |index, int|
      # Load the device into the devices hash only if it doesn't already exist.
      # This prevents multiple DB queries for the same device.
      devices[int.device] ||= Device.fetch_from_db(db: @@db, device: int.device)[0]
      devices[int.device].populate(nil, ['Interface']) if !int.physical? && devices[int.device].interfaces.empty?
      device = devices[int.device]

      # This code ensures we get all children of parent interfaces, and that
      # the child interfaces are positioned directly after their parent (for
      # tablesorter parent/child relationship to work)
      children = device.get_children(parent_index: int.index)
      unless children.empty?
        ints.delete(index)
        ints[index] = int
        children.each do |child_int|
          child_index = "#{child_int.device}_#{child_int.index}"
          valid_children[child_index] = true # for lookup below, to determine if we have this child's parent
          ints.delete(child_index)
          ints[child_index] = child_int
        end
      end
    end

    ints.each do |index, int|

      int_data = JSON.parse(int.to_json)['data']
      # Create the details field as appropriate for the int
      int_data['td_bps_hidden'] = if_cell_bps_hidden(int)
      int_data['td_int_link'] = if_cell_int_link(@@config.settings, int)
      int_data['td_device'] = device_link(int.device)
      int_data['td_link_status'] = if_cell_link_status(int, devices[int.device])
      int_data['td_link_type'] = if_cell_link_type(int, devices[int.device])
      int_data['td_neighbor'] = if_cell_neighbor(int)
      int_data['td_bps_in'] = if_cell_bps_in(int)
      int_data['td_bps_out'] = if_cell_bps_out(int)
      int_data['td_speed'] = if_cell_speed(int)
      int_data['child'] = int.child? && valid_children[index]
      int_data['id'] = index
      data['data'].push(int_data)
    end
    return JSON.generate(data)

  end


  get '/ajax/devices' do

    devices = Device.fetch_from_db(db: @@db)

    data = []

    devices.each do |device|
      temp = JSON.parse(device.to_json)['data']
      temp['_list_display_'] = device_link(temp['device'])
      temp.delete_if do |attribute, val|
        %w(temps psus memory fans cpus interfaces).include? attribute
      end
      data.push temp
    end
    return JSON.generate(data)

  end


end
