class Game < ApplicationRecord
  enum state: {
    initializing: 0,
    player_number_confirmed: 1,
    running: 2,
    round_end: 3,
    completed: 4
  }, _prefix: true

  scope :playing, -> { where.not(state: :completed) }

  before_create do
    self.state = :initializing
    self.uuid ||= SecureRandom.base36(24) # could be conflict but it's ok
  end

  after_create do
    if players.size >= 2
      self.state_player_number_confirmed!
      Utils::Redis.lpush(
        "game:#{uuid}",
        {
          event: "game_created",
          data: {
            game_id: uuid,
            room_id: room_id,
            players: players
          },
          time: created_at,
          ex: Rails.configuration.redis.expiration.seconds.from_now
        }.to_json
      )
    end
  end

  after_update :handle_round_end, if: -> { state_player_number_confirmed? || state_round_end? }

  def handle_round_end
    if has_winner?
      self.state_completed!

    else

      Utils::Redis.set("game:#{uuid}:current_player_position", 0)
      GameJob::UpdatePlayersStatJob.perform_later(self)
      GameJob::DealCardJob.perform_later(self)
    end
  end

  def self.create_mock_game
    Game.create!(
      room_id: "dev_#{SecureRandom.base36(20)}",
      players: [Games::Player.new({id: 'developer000000000000000', nickname: 'Me', email: 'dev@cucumbers.io'}).to_json]
    )
  end

  def ready?
    state.to_sym >= :running
  end

  def wrap_players
    players.map { |p| Games::Player.build_from_game(game: self, player_id: p["id"]) }
  end

  def has_winner?
    wrap_players.one?(&:is_out?)
  end

  def remaining_players
    wrap_players.reject(&:is_out?)
  end

  def last_events(limit: 10)
    Utils::Redis.lrange("game:#{uuid}", 0, limit).map do |event|
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
    self.players = players.map do |player|
      player = Games::Player.build_from_game(game: self, player_id: player["id"])
      player.deal_cards(cards.pop(7)) unless player.is_out?
      player.to_json
    end
    self.save!
  end

  def player_cards(player_id)
    players.find { |p| p["id"] == player_id }["cards"]
  end

  #
  #
  # @param [String] player_uuid
  # @param [String] card_id
  def play_card(player_id:, card_id:)
    cards = player_cards(player_id)
    if cards.index(card_id.to_i)
      GameJob::PlayCardJob.perform_now(self, card_id.to_i, player_id)
      return OpenStruct.new(errors: [])
    else
      return OpenStruct.new(errors: ["card not found"])
    end
  end
end
