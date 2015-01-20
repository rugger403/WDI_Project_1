require 'sinatra/base'
require 'sinatra/reloader'
require 'redis'
require 'uri'
require 'httparty'
require 'pry'

require_relative 'database_helper.rb'
require_relative 'server'

run Halftime::Server
