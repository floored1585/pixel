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
    device = params[:device]
    device_partial = params[:device_partial]
    hw_type = params[:hw_type]
    types = params[:type] ? params[:type].split('$') : nil

    events = ComponentEvent.fetch_from_db(
      start_time: start_time, end_time: end_time, types: types, db: @@db, limit: limit,
      device: device, hw_type: hw_type, device_partial: device_partial
    )

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
