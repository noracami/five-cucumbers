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

    def self.rpush(key, value, ex: Rails.configuration.redis.expiration)
      client.expire(key, ex)
      client.rpush(key, value)
    end

    def self.lpush(key, value, ex: Rails.configuration.redis.expiration)
      client.expire(key, ex)
      client.lpush(key, value)
    end

    def self.lrange(key, start = 0, stop = -1)
      client.lrange(key, start, stop)
    end

    def self.lindex(key, index = 0)
      client.lindex(key, index)
    end

    def self.lpop(key, count)
      client.lpop(key, count)
    end

    def self.del(key)
      client.del(key)
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

    def self.initialize_trick(game_uuid)
      del("game:#{game_uuid}:trick")
      set("game:#{game_uuid}:trick_count", 1)
    end

    def self.read_trick(game_uuid)
      lrange("game:#{game_uuid}:trick").map { |id| Games::Card.new(id: id) }
    end

    def self.read_last_played_card(game_uuid)
      return nil if lindex("game:#{game_uuid}:trick", 0).nil?

      Games::Card.new(id: lindex("game:#{game_uuid}:trick", 0))
    end

    def self.play_card_to_trick(game_uuid, card)
      lpush("game:#{game_uuid}:trick", card)

      # increment trick count
    end
  end
end
