module GameJob
  class DealCardJob < ApplicationJob
    def perform(game)
      game.deal_cards
      game.players.each do |player|
        player = Games::Player.new(player)
        cards = player.cards
        Turbo::StreamsChannel.broadcast_update_to(
          "game_#{game.id}",
          target: "actions_#{player.id}",
          partial: "frontend/games/actions",
          locals: { game:, cards:, is_your_turn: player.id == current_player_id(game) }
        )
      end
      game.state_running!
    end

    private

    def current_player_id(game)
      current_player_position = Utils::Redis.get("game:#{game.uuid}:current_player_position").to_i
      game.players[current_player_position]["id"]
    end
  end
end
