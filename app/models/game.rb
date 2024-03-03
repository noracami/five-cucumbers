class Game < ApplicationRecord
  enum state: {
    initializing: 0,
    initialized: 1,
    running: 2,
    completed: 3
  }, _prefix: true

  scope :playing, -> { where.not(state: :completed) }

  before_create do
    self.state = :initializing
    self.uuid ||= SecureRandom.base36(24) # could be conflict but it's ok
  end

  after_create do
    $redis.set "game:#{uuid}:current_player_position", 0, ex: 1.hour.from_now
    GameJob::DealJob.perform_now(self)
  end

  def last_events(limit: 10)
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
    cards = (1..60).to_a.shuffle
    players.each do |player|
      key = "game:#{uuid}:cards:#{player["id"]}"
      $redis.lpush(key, cards.pop(7))
    end
  end

  def player_cards(player_id)
    key = "game:#{uuid}:cards:#{player_id}"
    $redis.lrange(key, 0, -1)
  end
end
