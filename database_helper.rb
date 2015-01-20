require 'date'
require 'redis'


module Halftime
  module DatabaseHelper
    REDIS = Redis.new

    def flushdb
      REDIS.flushdb #flushes Redis database
    end

    # def set_vote_incrementor(value)
    #   REDIS.set("post_id", 1000)
    # end

    # def last_post_id
    #   REDIS.get("post_id")
    # end

    # def post_ids
    #   REDIS.lrange("post_ids", 0, -1)
    # end

    def post(id)
      REDIS.hgetall("post:#{id}") #gets all information for the given id
    end

    def posts
      post_ids.map {|id| post(id).merge({"id" => id})} #takes all the post ids and merges them
    end

    # def create_post(params)
    #   id = REDIS.incr("post_id")

    #   # ensure that the date fits the correct convention if it exists
    #   if params["date"]
    #     params["date"] = Date.parse(params["date"]).strftime("%b %-d, %Y")
    #   end

    #   data = set_defaults_for(params)

    #   REDIS.mapped_hmset("post:#{id}", data)
    #   REDIS.lpush("post_ids", id)
    #   id
    # end

    # def set_defaults_for(params)
    #   default_data = {
    #     # "image"            => "",
    #     "date"             => Date.today.strftime("%b %-d, %Y"),
    #     "tags"             => "",
    #     "author"           => "anonymous",
    #     "author_thumbnail" => "http://goo.gl/KQUfGE",
    #     "likes"            => 0
    #   }
    #   default_data.merge(params)
    # end
  end
end
