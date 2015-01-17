require 'httparty'
require 'pry'
require_relative 'database_helper'



module Halftime
  class Server < Sinatra::Base

    helpers Halftime::DatabaseHelper

    enable :logging, :sessions

    configure :development do
      register Sinatra::Reloader
      $redis = Redis.new

    end

    get('/') do
      # builds out the params we'll need to pass to Facebook
      query_params = URI.encode_www_form({
        :client_id     => ENV["FACEBOOK_OAUTH_ID"],
        :redirect_uri => "http://localhost:9292/oauth_callback"
      })
        # :scope         => "",    # part of many OAuth requests, but not with Facebook

      @facebook_auth_url = "https://www.facebook.com/dialog/oauth?" + query_params


       render(:erb, :index)

    end

    get '/home' do
      @ncaab =(post_ids = $redis.lrange("ncaab", 0, -1) #reading all the index values for ncaab
      @posts = post_ids.map do |id|
        $redis.hgetall("ncaab:#{id}")
      end)
      @nfl = (post_ids = $redis.lrange("nfl", 0, -1)
        @posts = post_ids.map do |id|
        $redis.hgetall("nfl:#{id}")
      end)
      @nhl = (post_ids = $redis.lrange("nhl", 0, -1)
      @posts = post_ids.map do |id|
        $redis.hgetall("nhl:#{id}")
      end)
      @mma = (post_ids = $redis.lrange("mma", 0, -1)
      @posts = post_ids.map do |id|
        $redis.hgetall("mma:#{id}")
      end)
      #@name = get_user_info
      render(:erb,:home, layout: :default)

    end

    get '/NCAAB' do
      @league_name = "NCAAB"
      post_ids = $redis.lrange("ncaab", 0, -1) #reading all the index values for ncaab
      @posts = post_ids.map do |id|
        $redis.hgetall("ncaab:#{id}")
      end
      render(:erb,:league, layout: :default)
    end


    get '/NCAAB/:id' do
      @post = post(params[:id])
      render(:erb, :show, :layout => :default)
    end

    post '/NCAAB' do
      id = $redis.incr("ncaab_id")
      post = params["post"]
      tags = params["tags"]
      photo = params["image_url"]
      time = Time.now
      $redis.hmset("ncaab:#{id}", "post", post, "tags",
        tags, "time", time, "photo", photo)
      $redis.lpush("ncaab", id)
      redirect to('/NCAAB/:id')
    end

    # # delete '/NCAAB' do
    # #   name = params["ncaab:#{id}"]
    # #   $redis.del("ncaab:#{id}")
    # #   redirect('/NCAAB')
      # end



    get '/NFL' do
      @league_name = "NFL"
      post_ids = $redis.lrange("nfl", 0, -1) #reading all the index values for nfl
      @posts = post_ids.map do |id|
        $redis.hgetall("nfl:#{id}")
      end
      render(:erb,:league, layout: :default)
    end

     post '/NFL' do
       id = $redis.incr("nfl_id")
       post = params["post"]
       tags = params["tags"]
       time = Time.now
       $redis.hmset("nfl:#{id}", "post", post, "tags", tags, "time", time)
       $redis.lpush("nfl", id)
       redirect to('/NFL')
     end

    get '/NHL' do
      @league_name = "NHL"
      post_ids = $redis.lrange("nhl", 0, -1)
      @posts = post_ids.map do |id|
        $redis.hgetall("nhl:#{id}")
      end
      render(:erb, :league, layout: :default)
    end

     post '/NHL' do
      id = $redis.incr("nhl_id")
      post = params["post"]
      tags = params["tags"]
      time = Time.now
      $redis.hmset("nhl:#{id}", "post", post, "tags", tags, "time", time)
      $redis.lpush("nhl", id)
      redirect to('/NHL')
    end

    get '/MMA' do
      @league_name = "MMA"
      post_ids = $redis.lrange("mma", 0, -1)
      @posts = post_ids.map do |id|
        $redis.hgetall("mma:#{id}")
      end
      render(:erb, :league, layout: :default)
    end

    post '/MMA' do
      id = $redis.incr("mma_id")
      post = params["post"]
      tags = params["tags"]
      time = Time.now
      $redis.hmset("mma:#{id}", "post", post, "tags", tags, "time", time)
      $redis.lpush("mma", id)
      redirect to('/MMA')
    end

    get("/oauth_callback") do
      response = HTTParty.post(
        "https://graph.facebook.com/oauth/access_token?",

        :body => {
          :client_id     => ENV["FACEBOOK_OAUTH_ID"],
          :redirect_uri  => "http://localhost:9292/oauth_callback",
          :client_secret => ENV["FACEBOOK_OAUTH_SECRET"],
          :code          => params[:code],
        },

        :headers => {
          "Accept" => "application/json"
        })
      session[:access_token] = response["access_token"]
      #binding.pry
      redirect to('/home')
    end

    get('/logout') do
      session[:name] = session[:access_token] = nil # dual assignment!
      render(:erb, :logout)
    end

    # ########################
    # # Helper methods
    # ########################

    # authorized API call (after OAuth complete!)
    def get_user_info
      response = HTTParty.get(
        "https://graph.facebook.com",
        :headers => {
          "Authorization" => "Bearer #{session[:access_token]}",
          "User-Agent"    => "OAuth Test App"
        }
      )
      session[:email]      = response["email"]
      session[:user_id]   = response["name"]
      session[:user_image]= response["avatar_url"]
      session[:provider]   = "Facebook"
    end
  end
end
