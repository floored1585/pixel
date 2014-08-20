class Pixel < Sinatra::Base

  get '/v1/devices/:device' do |device|
    JSON.generate get_ints_device(@@settings, @@db, device)
  end

  post '/v1/devices' do
    request.body.rewind
    devices = JSON.parse(request.body.read)
    post_devices(@@settings, @@db, devices)
    return 200
  end

end
