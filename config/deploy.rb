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

set :application, 'pixel'
set :repo_url, 'https://github.com/floored1585/pixel.git'
set :rvm_ruby_version, '2.2.0@sinatra-2.2'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
# set :deploy_to, '/var/www/my_app'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute 'mkdir', release_path.join('tmp')
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  desc 'Wake up application!'
  task :wakeup do
    on roles(:app) do
      execute "curl -s -D - http://127.0.0.1:80/v2/wakeup -o /dev/null"
    end
  end

  task :symlinks do
    on roles(:app) do
      execute "mkdir -p #{shared_path}/config"
      execute "mkdir -p #{shared_path}/log"
      execute :touch, shared_path.join('log/messages.log') unless File.file?(shared_path.join('log/messages.log'))
      execute :touch, shared_path.join('config/hosts.yaml') unless File.file?(shared_path.join('config/hosts.yaml'))
      execute "ln -s #{shared_path}/config/hosts.yaml #{release_path}/config/hosts.yaml"
      execute "ln -s #{shared_path}/config/config.yaml #{release_path}/config/config.yaml"
      execute "ln -s #{shared_path}/log/messages.log #{release_path}/messages.log"
    end
  end

  after :updating, :symlinks
  after :publishing, :restart
  after :restart, :wakeup

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
