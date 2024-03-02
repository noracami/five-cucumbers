module GameJob
  class DealJob < ApplicationJob
    def perform(game)
      # Do something later
      game.deal_cards
      game.players.each do |player|
        cards = $redis.lrange("game:#{game.uuid}:cards:#{player["id"]}", 0, -1)
        Turbo::StreamsChannel.broadcast_update_to(
          "game_#{game.id}",
          target: "actions_#{player["id"]}",
          partial: "frontend/games/actions",
          locals: { game:, cards:, is_your_turn: player["id"] == current_player(game) }
        )
      end
    end

    private

    def current_player(game)
      game.players[$redis.get("game:#{game.uuid}:current_player_position").to_i]["id"]
    end
  end
end
