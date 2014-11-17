require 'rubygems'
require 'bundler'

Bundler.require

Rack::Utils.key_space_limit = 524288

require './pixel'
run Pixel
