module GameJob
  class PrepareRoundJob < ApplicationJob
    def perform(game_id = nil, last_trick_winner_id: nil)
      game = Game.find(game_id)
      game.deal_cards!
      game.decide_first_player(last_trick_winner_id)
      game.initialize_trick

      game.wrap_players.each do |player|
        Utils::Notify.new(game).update_player_actions(player).update_players_stat(player.id)
      end
    end
  end
end
