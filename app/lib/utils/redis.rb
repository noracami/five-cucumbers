module Utils
  class Redis
    # common methods for redis
    def self.get(key)
      client.get(key)
    end

    def self.set(key, value, ex: Rails.configuration.redis.expiration)
      client.set(key, value, ex: ex)
    end

    def self.client
      $redis
    end

    def self.lpush(key, value, ex: Rails.configuration.redis.expiration)
      client.expire(key, ex)
      client.lpush(key, value)
    end

    def self.lrange(key, start, stop)
      client.lrange(key, start, stop)
    end

    def self.lpop(key, count)
      client.lpop(key, count)
    end

    # game specific methods
    def self.last_10_game_events(game_uuid)
      lrange("game:#{game_uuid}:events", 0, 9).map do |event|
        hash = JSON.parse(event)
        ret = []
        ret << hash["event"]
        ret << hash["time"].to_time
        ret << hash["data"]
        ret
      end
    end
  end
end
