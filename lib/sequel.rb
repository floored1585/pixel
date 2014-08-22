#!/usr/bin/env ruby

require 'sequel'

module SQ

  def self.initiate
    config_file = Configfile.retrieve

    user = config_file['pg_conn']['user']
    pass = config_file['pg_conn']['pass']
    database = config_file['pg_conn']['db']
    host = config_file['pg_conn']['host']

    Sequel.connect(:adapter => 'postgres', :host => host, :user => user, :password => pass, :database => database)
  end

end
