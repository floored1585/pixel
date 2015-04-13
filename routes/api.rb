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

  get '/v2/device/*/interface/*' do |device, index|
    JSON.generate( get_interface(@@settings, @@db, device, index) )
  end
  get '/v2/device/*/interfaces' do |device|
    JSON.generate( get_interface(@@settings, @@db, device) )
  end

  get '/v2/device/*/cpu/*' do |device, index|
    JSON.generate( get_cpu(@@settings, @@db, device, index) )
  end
  get '/v2/device/*/cpus' do |device|
    JSON.generate( get_cpu(@@settings, @@db, device) )
  end

  get '/v2/device/*/fan/*' do |device, index|
    JSON.generate( get_fan(@@settings, @@db, device, index) )
  end
  get '/v2/device/*/fans' do |device|
    JSON.generate( get_fan(@@settings, @@db, device) )
  end

  get '/v2/device/*/memory/*' do |device, index|
    JSON.generate( get_memory(@@settings, @@db, device, index) )
  end
  get '/v2/device/*/memory' do |device|
    JSON.generate( get_memory(@@settings, @@db, device) )
  end

  get '/v2/device/*/psu/*' do |device, index|
    JSON.generate( get_psu(@@settings, @@db, device, index) )
  end
  get '/v2/device/*/psus' do |device|
    JSON.generate( get_psu(@@settings, @@db, device) )
  end

  get '/v2/device/*/temperature/*' do |device, index|
    JSON.generate( get_temperature(@@settings, @@db, device, index) )
  end
  get '/v2/device/*/temperatures' do |device|
    JSON.generate( get_temperature(@@settings, @@db, device) )
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
