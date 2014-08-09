require 'rubygems'
require 'bundler'

Bundler.require

require './pixel'
run Sinatra::Application
