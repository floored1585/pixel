class Pixel < Sinatra::Base

  get '/' do
    # Start timer
    beginning = Time.now

    ints_down = get_ints_down(@@settings, @@db)
    ints_saturated = get_ints_saturated(@@settings, @@db)
    ints_discarding = get_ints_discarding(@@settings, @@db)
    cpus_high = get_cpus_high(@@settings, @@db)
    memory_high = get_memory_high(@@settings, @@db)
    hw_problems = get_hw_problems(@@settings, @@db)
    alarms = get_alarms(@@settings, @@db)
    poller_failures = get_poller_failures(@@settings, @@db)

    db_elapsed = '%.2f' % (Time.now - beginning)

    erb :alerts, :locals => {
      :title => 'Alerts',
      :settings => @@settings,
      :db => @@db,
      :poller_failures => poller_failures,
      :ints_discarding => ints_discarding,
      :ints_saturated => ints_saturated,
      :ints_down => ints_down,
      :cpus_high => cpus_high,
      :memory_high => memory_high,
      :hw_problems => hw_problems,
      :alarms => alarms,
      :db_elapsed => db_elapsed,
    }
  end


  get '/devices' do
    erb :devices
  end


  get '/devices2' do
    erb :devices2
  end


  get '/events' do
    erb :events
  end


  get '/saturation' do
    util = params[:util] || 90
    util = util.to_i
    speed = params[:speed].to_i if params[:speed]

    # Start timer
    beginning = Time.now
    interfaces = get_ints_saturated(@@settings, @@db, util: util, speed: speed)
    db_elapsed = '%.2f' % (Time.now - beginning)

    erb :saturation, :locals => {
      :title => 'Saturation Data',
      :settings => @@settings,
      :db => @@db,
      :interfaces => interfaces,
      :util => util,
      :speed => speed,
      :db_elapsed => db_elapsed,
    }

  end


  get '/device/search' do
    target = params[:device_input] || 'Enter a device in the search box'
    redirect to(target.empty? ? '/' : "/device/#{target}")
  end


  get '/device/*' do |device_name|
    # Start timer
    beginning = Time.now

    device = Device.fetch(device_name, ['all'])

    # How long did it take us to query the database
    db_elapsed = '%.2f' % (Time.now - beginning)

    erb :device, :locals => {
      :settings => @@settings,
      :device_name => device_name,
      :device => device,
      :db_elapsed => db_elapsed,
    }
  end


end
