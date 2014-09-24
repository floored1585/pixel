class Pixel < Sinatra::Base

  get '/' do
    # Start timer
    beginning = Time.now

    ints_saturated = get_ints_saturated(@@settings, @@db)
    ints_discarding = get_ints_discarding(@@settings, @@db)
    ints_down = get_ints_down(@@settings, @@db)
    cpus_high = get_cpus_high(@@settings, @@db)
    memory_high = get_memory_high(@@settings, @@db)

    db_elapsed = '%.2f' % (Time.now - beginning)

    erb :dashboard, :locals => {
      :title => 'Dashboard!',
      :settings => @@settings,
      :ints_discarding => ints_discarding,
      :ints_saturated => ints_saturated,
      :ints_down => ints_down,
      :cpus_high => cpus_high,
      :memory_high => memory_high,
      :db_elapsed => db_elapsed,
    }
  end

  get '/device/search' do
    target = params[:device_input] || 'Enter a device in the search box'
    redirect to(target.empty? ? '/' : "/device/#{target}")
  end

  get '/device/:device' do |device|
    # Start timer
    beginning = Time.now

    devices = get_device(@@settings, @@db, device)

    # How long did it take us to query the database
    db_elapsed = '%.2f' % (Time.now - beginning)

    erb :device, :locals => {
      :settings => @@settings,
      :device => device,
      :data => devices[device],
      :db_elapsed => db_elapsed,
    }
  end

end
