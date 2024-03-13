module Utils
  class Redis
    def self.client
      $redis
    end

    # common methods for redis
    def self.scan(cursor = 0, match: nil, count: 10)
      client.scan(cursor, match: match, count: count)
    end

    def self.type(key)
      client.type(key)
    end

    def self.get(key)
      client.get(key)
    end

    def self.set(key, value, ex: Rails.configuration.redis.expiration)
      client.set(key, value, ex: ex)
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
    def self.logs(game_uuid)
      redis_logs = {}
      cursor = 0

      while cursor != "0"
        cursor, result = Utils::Redis.scan(cursor, match: "game:#{game_uuid}:*")
        result.each do |key|
          case Utils::Redis.type(key)
          when "list"
            redis_logs[key] = Utils::Redis.lrange(key, 0, -1)
            if key.end_with?("events")
              redis_logs[key] = redis_logs[key].map { |event| JSON.parse(event) }
            end
          when "string"
            redis_logs[key] = Utils::Redis.get(key)
          else
            Rails.logger.warn "Unknown type: #{Utils::Redis.type(key)} for key: #{key}"
          end
        end
      end

      redis_logs
    end

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

    def self.initialize_trick(game_uuid, count = 1)
      del("game:#{game_uuid}:trick")
      set("game:#{game_uuid}:trick_count", count)
    end

    def self.trick_count(game_uuid)
      get("game:#{game_uuid}:trick_count").to_i
    end

    def self.n_of_cards_in_the_trick(game_uuid)
      lrange("game:#{game_uuid}:trick").size
    end

    def self.read_trick(game_uuid)
      lrange("game:#{game_uuid}:trick").map { |id| Games::Card.new(id: id) }
    end

    def self.largest_card_in_the_trick(game_uuid)
      read_trick(game_uuid).max_by(&:numbers)
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
