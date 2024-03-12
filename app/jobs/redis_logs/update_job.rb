module RedisLogs
  class UpdateJob < ApplicationJob
    def perform(game)
      redis_logs = Utils::Redis.logs(game.uuid)

      Turbo::StreamsChannel.broadcast_update_to(
        "game_#{game.id}",
        target: "redis_logs_game_#{game.id}",
        partial: "frontend/games/game_redis_logs",
        locals: { redis_logs:, game: }
      )
    end
  end
end
