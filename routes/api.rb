class Pixel < Sinatra::Base

  get '/v1/devices/:device' do |device|
    JSON.generate get_ints_device(@@settings, @@db, device)
  end

  get '/v1/poller/poke' do
    puts "Request to check for work"
    Poller.check_for_work
  end

  post '/v1/devices' do
    request.body.rewind
    devices = JSON.parse(request.body.read)
    post_devices(@@settings, @@db, devices)

    # Probably needs fixing, just put this here
    # to shut up some errors about returning non-strings
    return 200
  end

end
