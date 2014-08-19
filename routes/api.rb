class Pixel < Sinatra::Base

  get '/v1/devices/:device' do |device|
    JSON.generate get_ints_device(@@settings, @@db, device)
  end

end
