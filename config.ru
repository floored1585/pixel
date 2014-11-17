require 'rubygems'
require 'bundler'

Bundler.require

Rack::Utils.key_space_limit = 262144

require './pixel'
run Pixel
