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
    list_devices(@@settings, @@db)
  end

  get '/v1/devices' do
    device = params[:device]
    JSON.generate( get_device(@@settings, @@db, device) )
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
