require 'rubygems'
require 'bundler'

Bundler.require

Rack::Utils.key_space_limit = 1048576

require './pixel'
run Pixel
