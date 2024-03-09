module Utils
  class GameHelper
    def self.is_your_turn?(game, player_id)
      game.players[current_player_position(game)]["id"] == player_id
    end

    private

    def self.current_player_position(game)
      Utils::Redis.get("game:#{game.uuid}:current_player_position").to_i
    end
  end
end
