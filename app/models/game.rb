class Game < ApplicationRecord
  enum state: {
    initializing: 0,
    initialized: 1,
    running: 2,
    completed: 3
  }, _prefix: true

  scope :playing, -> { where.not(state: :completed) }

  def last_events(limit: 10)
    # events.order(created_at: :desc).limit(limit)
    # mock events
    # [
    #   { id: 1, name: "event 1", created_at: Time.current },
    #   { id: 2, name: "event 2", created_at: Time.current },
    #   { id: 3, name: "event 3", created_at: Time.current },
    #   { id: 4, name: "event 4", created_at: Time.current },
    #   { id: 5, name: "event 5", created_at: Time.current }
    # ].map(&:values)
    $redis.lrange("game:#{uuid}", 0, limit).map do |event|
      hash = JSON.parse(event)
      ret = []
      ret << hash["event"]
      ret << hash["time"].to_time
      ret << hash["data"]
      ret
    end
  end

  def deal_cards
    # mock cards
    cards = (1..60).to_a.shuffle
    players.each do |player|
      key = "game:#{uuid}:cards:#{player["id"]}"
      $redis.lpush(key, cards.pop(5))
    end
  end

  def player_cards(player_id)
    key = "game:#{uuid}:cards:#{player_id}"
    $redis.lrange(key, 0, -1)
  end
end
