#!/usr/bin/env ruby

require "sequel"
require_relative 'yaml'

module SQ

  def SQ.initiate
    config_file = Configfile.retrieve

    user = config_file['pg_conn']['user']
    pass = config_file['pg_conn']['pass']
    database = config_file['pg_conn']['db']
    host = config_file['pg_conn']['host']

    db = Sequel.connect(:adapter => 'postgres', :host => host, :user => user, :password => pass, :database => database)
    return db
  end

end
