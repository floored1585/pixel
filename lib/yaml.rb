#!/usr/bin/env ruby

require 'yaml'

module Configfile

  def Configfile.retrieve
    config_file = YAML.load_file(File.expand_path('../../config/settings.yaml', __FILE__))
    return config_file
  end

end
