#!/usr/bin/env ruby

require 'yaml'

module Configfile

  def self.retrieve
    YAML.load_file(File.expand_path('../../config/settings.yaml', __FILE__))
  end

end
