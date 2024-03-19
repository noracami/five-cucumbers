module AiJobs
  class AutoMoveJob < ApplicationJob
    queue_as :ai_jobs

    def perform(game_id)
      sleep rand(0.5..1.0)

      game = Game.find(game_id)
      player = Games::Player.build_from_game(game:, player_id: game.current_player_id)

      if player.is_ai?
        # play card automatically
        ret = player.play_card
        raise "Error playing card: #{ret.errors.full_messages.join(", ")}" if ret.errors.any?

        RedisLogs::UpdateJob.perform_now(game)

        game.reload
        AiJobs::AutoMoveJob.perform_later(game_id) if game.wrap_players.find { |p| p.id == game.current_player_id }&.is_ai?
      end
    end
  end
end
