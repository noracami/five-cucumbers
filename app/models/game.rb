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

  after_update :handle_the_first_round_of_game, if: -> { state_player_number_confirmed? }
  # after_update :handle_round_end, if: -> { state_round_end? }

  def handle_the_first_round_of_game
    GameJob::PrepareRoundJob.perform_later(id)
  end

  def initialize_trick
    Utils::Redis.initialize_trick(uuid)
  end

  def decide_player_order(last_trick_winner_id = nil)
    candidates = wrap_players.cycle(2).to_a
    if last_trick_winner_id.nil?
      start_player = candidates.sample
    else
      start_player_index = candidates.index { |p| p.id == last_trick_winner_id }
      start_player_index += 1 while candidates[start_player_index].is_out?
      start_player = candidates[start_player_index]
    end

    player_order = remaining_players.rotate(remaining_players.index { |p| p.id == start_player.id }).map(&:id)
    Utils::Redis.del("game:#{uuid}:player_order")
    Utils::Redis.rpush("game:#{uuid}:player_order", player_order)
    Utils::Notify.new(self).push_it_is_turn_for_player_event(start_player.nickname)
  end

  # def handle_round_end
  #   if has_winner?
  #     self.state_completed!

  #   else

  #     Utils::Redis.set("game:#{uuid}:current_player_position", 0)
  #     GameJob::UpdatePlayersStatJob.perform_later(self)
  #     GameJob::DealCardJob.perform_later(self)
  #   end
  # end

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

  def remaining_players
    wrap_players.reject(&:is_out?)
  end

  def has_winner?
    remaining_players.size == 1
  end

  def winner
    (has_winner? && remaining_players.first) || Games::Player.new(nickname: "No one")
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

  def current_player_id
    card_count_of_trick = Utils::Redis.lrange("game:#{uuid}:trick").size
    Utils::Redis.lindex("game:#{uuid}:player_order", card_count_of_trick)
  end

  def deal_cards!
    cards = (1..60).to_a.shuffle
    self.players = wrap_players.map do |player|
      if player.is_out?
        player.deal_cards([])
      else
        player.deal_cards(cards.pop(7))
      end
      player.to_json
    end
    self.state = :running
    self.save!
  end

  def increase_rounds
    Utils::Redis.incr("game:#{uuid}:rounds")
  end

  def current_rounds
    rounds = Utils::Redis.get("game:#{uuid}:rounds").to_i
    rounds.zero? ? nil : rounds
  end

  def player_cards(player_id)
    players.find { |p| p["id"] == player_id }["cards"]
  end

  def how_many_tricks_played
    Utils::Redis.trick_count(uuid)
  end
end
