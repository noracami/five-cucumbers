module GameJob
  class ShowEndJob < ApplicationJob
    def perform(game_id)
      game = Game.find(game_id)
      game_notifier = Utils::Notify.new(game)
      game_notifier.push_game_ended_event

      # save logs
      game_logs = Utils::Redis.game_logs(game.uuid)
      game.update!(game_logs: game_logs.to_json, state: "completed")

      game.wrap_players.each do |player|
        game_notifier.push_error_event(player.id, "Game is completed")
        game_notifier.update_player_actions(player).update_players_stat(player.id)
      end
      game_notifier.update_game_rounds
      game_notifier.update_game_event_logs
    end
  end
end
