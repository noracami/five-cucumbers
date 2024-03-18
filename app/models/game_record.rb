class GameRecord < ApplicationRecord
  belongs_to :game

  validates :winner_id, :winner_nickname, :rounds, :player_number, :start_time, presence: true

  def self.load_from_game(game)
    new({
      game: game,
      winner_id: game.winner.id,
      winner_nickname: game.winner.nickname,
      rounds: game.current_rounds,
      player_number: game.players.count,
      start_time: game.created_at
    })
  end

  def self.create_game_record(game)
    load_from_game(game).save
  end

  def duration_in_seconds
    duration.to_i
  end

  def duration_inspect
    duration.inspect
  end

  private

  def duration
    ActiveSupport::Duration.build((created_at - start_time).to_i)
  end
end
