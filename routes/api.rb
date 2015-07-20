class Pixel < Sinatra::Base


  #
  # GETS
  #
  get '/v2/wakeup' do
    return 200
  end

  get '/v2/fetch_poll/*/*' do |poller, count|
    JSON.generate( fetch_poll(@@settings, @@db, count.to_i, poller) )
  end

  get '/v2/events/component/*/*/*' do |device, hw_type, index|
    start_time = params[:start_time]
    end_time = params[:end_time]
    limit = params[:limit]
    types = params[:types] ? params[:types].split(',') : nil
    JSON.generate(ComponentEvent.fetch_from_db(
      device: device, index: index, hw_type: hw_type, start_time: start_time,
      end_time: end_time, types: types, db: @@db, limit: limit
    ))
  end

  get '/v2/events/component/*' do |comp_id|
    # Return an empty array unless comp_id is numeric
    return '[]' unless comp_id.to_s =~ /^[0-9]+$/

    start_time = params[:start_time]
    end_time = params[:end_time]
    types = params[:types] ? params[:types].split(',') : nil

    JSON.generate(ComponentEvent.fetch_from_db(
      comp_id: comp_id, start_time: start_time, end_time: end_time, types: types, db: @@db
    ))
  end

  get '/v2/events/component' do
    start_time = params[:start_time]
    end_time = params[:end_time]
    limit = params[:limit]
    device = params[:device]
    hw_type = params[:hw_type]
    types = params[:types] ? params[:types].split(',') : nil

    events = ComponentEvent.fetch_from_db(
      start_time: start_time, end_time: end_time, types: types, db: @@db, limit: limit,
      device: device, hw_type: hw_type
    )

    if params[:ajax]
      data = {}
      data['meta'] = {}
      data['data'] = []
      events.each do |event|
        temp = JSON.parse(event.to_json)['data']
        component = Component.fetch_from_db(id: event.component_id, db: @@db).first
        temp['details'] = event.html_details(component)
        temp.merge!(JSON.parse(component.to_json)['data'])
        data['data'].push(temp)
      end
      return JSON.generate(data)
    end

    return JSON.generate(events)
  end

  get '/v2/device/*/*/*/id' do |device, hw_type, index|
    JSON.generate(
      { 'id' => Component.id_from_db(device: device, index: index, hw_type: hw_type, db: @@db) }
    )
  end

  get '/v2/component' do
    id = params[:id]
    device = params[:device]
    hw_types = params[:hw_types] ? params[:hw_types].split(',') : nil
    index = params[:index]
    limit = params[:limit]

    components = Component.fetch_from_db(
      device: device, index: index, hw_types: hw_types, db: @@db, limit: limit
    )

    return JSON.generate(components)
  end

  get '/v2/device/*' do |device|
    JSON.generate( get_device(@@settings, @@db, device) )
  end

  get '/v2/devices/populate' do
    populate_device_table(@@settings, @@db)
  end

  get '/v2/devices' do
    JSON.generate( list_devices(@@settings, @@db) )
  end

  get '/v1/series/rickshaw' do
    query = params[:query]
    attribute = params[:attribute]
    JSON.generate( Influx.query(query, attribute, @@db, :rickshaw) )
  end

  #get '/v1/series' do
  #  query = params[:query]
  #  JSON.generate( Influx.query(query) )
  #end

  get '/v2/poller/poke' do
    Poller.check_for_work(@@settings)
  end

  #
  # POSTS
  #
  post '/v2/devices/replace' do
    request.body.rewind
    devices = JSON.parse(request.body.read)
    add_devices(@@settings, @@db, devices, replace: true)
  end

  post '/v2/devices/add' do
    request.body.rewind
    devices = JSON.parse(request.body.read)
    add_devices(@@settings, @@db, devices)
  end

  #post '/v1/devices/delete' do
  #  request.body.rewind
  #  devices = JSON.parse(request.body.read)
  #  delete_devices(@@settings, @@db, devices, false)
  #end

  post '/v2/device' do
    request.body.rewind
    device = JSON.load(request.body.read)
    return 400 unless device.class == Device
    post_device(@@settings, @@db, device)
  end

  post '/v2/interface' do
    request.body.rewind
    interface = JSON.load(request.body.read)
    return 400 unless interface.class == Interface
    post_interface(@@settings, @@db, interface)
  end

  post '/v2/cpu' do
    request.body.rewind
    cpu = JSON.load(request.body.read)
    return 400 unless cpu.class == CPU
    post_cpu(@@settings, @@db, cpu)
  end

  post '/v2/fan' do
    request.body.rewind
    fan = JSON.load(request.body.read)
    return 400 unless fan.class == Fan
    post_fan(@@settings, @@db, fan)
  end

  post '/v2/memory' do
    request.body.rewind
    memory = JSON.load(request.body.read)
    return 400 unless memory.class == Memory
    post_memory(@@settings, @@db, memory)
  end

  post '/v2/psu' do
    request.body.rewind
    psu = JSON.load(request.body.read)
    return 400 unless psu.class == PSU
    post_psu(@@settings, @@db, psu)
  end

  post '/v2/temperature' do
    request.body.rewind
    temperature = JSON.load(request.body.read)
    return 400 unless temperature.class == Temperature
    post_temperature(@@settings, @@db, temperature)
  end

end
