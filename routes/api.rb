class Pixel < Sinatra::Base

  get '/v1/devices/fetch_poll' do
    count = params[:count] || 10
    poller_name = params[:hostname] || 'unknown'
    JSON.generate( get_devices_poller(@@settings, @@db, count.to_i, poller_name) )
  end

  get '/v1/devices/:device' do |device|
    JSON.generate( get_ints_device(@@settings, @@db, device) )
  end

  get '/v1/poller/poke' do
    Poller.check_for_work(@@settings, @@db)
  end

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
