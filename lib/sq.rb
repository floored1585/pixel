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

#!/usr/bin/env ruby

require 'sequel'

module SQ

  def self.initiate
    cfg = YAML.load_file(File.expand_path('../../config/config.yaml', __FILE__))

    return nil if cfg['api_only']

    host = cfg['host'] || '127.0.0.1'
    user = cfg['user']
    pass = cfg['pass']
    database = cfg['db'] || 'pixel'
    pool_timeout = cfg['pool_timeout'] || 10
    max_connections = cfg['max_connections'] || 10

    return nil unless (host && user && pass && database && pool_timeout && max_connections)

    Sequel.connect(
      :adapter => 'postgres',
      :host => host,
      :user => user,
      :password => pass,
      :database => database,
      :pool_timeout => pool_timeout,
      :max_connections => max_connections
    )
  end

end
