module GameJob
  class DealCardJob < ApplicationJob
    def perform(game_id: nil)
      game = Game.find(game_id)
      game.deal_cards
      game.wrap_players.each do |player|
        Turbo::StreamsChannel.broadcast_update_to(
          "game_#{game.id}",
          target: "actions_#{player.id}",
          partial: "frontend/games/actions",
          locals: { game:, current_player: player }
        )
      end
    end
  end
end
