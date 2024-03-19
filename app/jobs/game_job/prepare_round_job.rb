module GameJob
  class PrepareRoundJob < ApplicationJob
    def perform(game_id = nil, last_trick_winner_id: nil)
      game = Game.find(game_id)
      game.increase_rounds
      game.deal_cards!
      game.decide_player_order(last_trick_winner_id)
      game.initialize_trick

      game_notifier = Utils::Notify.new(game)
      game.wrap_players.each do |player|
        game_notifier.update_player_actions(player).update_players_stat(player.id)
      end
      game_notifier.update_game_event_logs
      game_notifier.update_game_rounds

      game.reload
      pp game.wrap_players.find { |p| p.id == game.current_player_id }
      AiJobs::AutoMoveJob.perform_later(game_id) if game.wrap_players.find { |p| p.id == game.current_player_id }.is_ai?
    end
  end
end
