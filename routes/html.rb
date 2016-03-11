#
# Pixel is an open source network monitoring system
# Copyright (C) 2016 all Pixel contributors!
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Pixel < Sinatra::Base

  get '/' do
    # Start timer
    beginning = Time.now

    ints_down = get_ints_down(@@db)
    ints_saturated = get_ints_saturated(@@db)
    ints_discarding = get_ints_discarding(@@db)
    cpus_high = get_cpus_high(@@db)
    memory_high = get_memory_high(@@db)
    hw_problems = get_hw_problems(@@db)
    alarms = get_alarms(@@db)
    poller_failures = get_poller_failures(@@db)

    db_elapsed = '%.2f' % (Time.now - beginning)

    erb :alerts, :locals => {
      :title => 'Alerts',
      :settings => @@config.settings,
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
    interfaces = get_ints_saturated(@@db, util: util, speed: speed)
    db_elapsed = '%.2f' % (Time.now - beginning)

    erb :saturation, :locals => {
      :title => 'Saturation Data',
      :settings => @@config.settings,
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
      :settings => @@config.settings,
      :device_name => device_name,
      :device => device,
      :db_elapsed => db_elapsed,
    }
  end


end
