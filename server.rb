module Halftime
  class Server < Sinatra::Base

    helpers Halftime::DatabaseHelper

    enable :logging, :sessions

    configure :development do
      register Sinatra::Reloader
      $redis = Redis.new
      require 'pry'
    end

    get('/') do
      # builds out the params we'll need to pass to Facebook
      query_params = URI.encode_www_form({
        :client_id     => ENV["FACEBOOK_OAUTH_ID"],
        :redirect_uri => "http://localhost:9292/oauth_callback"
      })
      @facebook_auth_url = "https://www.facebook.com/dialog/oauth?" + query_params
      render(:erb, :index)
    end


    def league_posts(league)
     post_ids = $redis.lrange(league, 0, -1)
     post_ids.map do |id|
        $redis.hgetall("#{league}:#{id}")
     end
    end


    get '/home' do
      # reading all the index values for each league
     @ncaab_posts = league_posts("ncaab")

     @nfl_posts = league_posts("nfl")

     @nhl_posts = league_posts("nhl")

     @mma_posts = league_posts("mma")

      # TODO make this work
      # @name = get_user_info
      render(:erb,:home, layout: :default)

    end

    get '/NCAAB' do
      #reading all the index values for ncaab
      @league_name = "NCAAB"
      @ncaab_posts = league_posts("ncaab")
      # Trying to create like buttons
      @like = $redis.get("likes")
      @dislike = $redis.get("dislikes")
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
      # $redis.incr("likes")
      # $redis.incr("dislikes")
      time = Time.now.strftime("%m/%d/%Y %H:%M")
      $redis.hmset("ncaab:#{id}", "post", post, "tags",
        tags, "time", time, "photo", photo)
      $redis.lpush("ncaab", id)
      redirect to('/NCAAB')
    end

    # # delete '/NCAAB' do
    # #   name = params["ncaab:#{id}"]
    # #   $redis.del("ncaab:#{id}")
    # #   redirect('/NCAAB')
      # end



    get '/NFL' do
      @league_name = "NFL"
      @nfl_posts = league_posts("nfl")
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
      @nhl_posts = league_posts("nhl")
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
      @mma_posts = league_posts("mma")
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
    end # get_user_info
  end
end
