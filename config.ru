require 'sinatra/base'
require 'sinatra/reloader'
require 'redis'
require_relative 'server'
require 'uri'
require 'httparty'
require 'pry'
require_relative 'database_helper.rb'


run Halftime::Server
