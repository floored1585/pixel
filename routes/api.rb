class Pixel < Sinatra::Base

  #
  # GETS
  #
  get '/v1/devices/fetch_poll' do
    count = params[:count] || 10
    poller_name = params[:hostname] || 'unknown'
    JSON.generate( get_devices_poller(@@settings, @@db, count.to_i, poller_name) )
  end

  get '/v1/devices/populate' do
    populate_device_table(@@settings, @@db)
  end

  get '/v1/devices/list' do
    JSON.generate( list_devices(@@settings, @@db) )
  end

  get '/v1/devices' do
    device = params[:device]
    component = params[:component]
    JSON.generate( get_device(@@settings, @@db, device, component) )
  end

  get '/v1/series/rickshaw' do
    query = params[:query]
    attribute = params[:attribute]
    JSON.generate( Influx.query(query, attribute, @@db, :rickshaw) )
  end

  get '/v1/series' do
    query = params[:query]
    JSON.generate( Influx.query(query) )
  end

  get '/v1/poller/poke' do
    Poller.check_for_work(@@settings, @@db)
  end

  #
  # POSTS
  #
  post '/v1/devices/add' do
    request.body.rewind
    devices = JSON.parse(request.body.read)
    add_devices(@@settings, @@db, devices)
  end

  post '/v1/devices' do
    request.body.rewind
    devices = JSON.parse(request.body.read)
    post_devices(@@settings, @@db, devices)
  end

end
