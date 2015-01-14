require 'httparty'


module FacebookOauth
  class Server < Sinatra::Base

    enable :logging, :sessions

    configure :development do
      register Sinatra::Reloader
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
      get_user_info
      redirect to('/')
    end

    get('/logout') do
      session[:name] = session[:access_token] = nil # dual assignment!
      redirect to("/")
    end

    # ########################
    # # Helper methods
    # ########################

    # authorized API call (after OAuth complete!)
    def get_user_info
      response = HTTParty.get(
        "https://api.github.com/user",
        :headers => {
          "Authorization" => "Bearer #{session[:access_token]}",
          "User-Agent"    => "OAuth Test App"
        }
      )
      session[:email]      = response["email"]
      session[:name]       = response["name"]
      session[:user_image] = response["avatar_url"]
      session[:provider]   = "Github"
    end

  end
end
