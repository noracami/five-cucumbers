module GameJob
  class PlayCardJob < ApplicationJob
    def perform(game, card, current_player)
      # Do something later
      current_player_position = $redis.get("game:#{game.uuid}:current_player_position").to_i
      if current_player["id"] != game.players[current_player_position]["id"]
        puts current_player["id"]
        puts game.players[current_player_position]["id"]
        Rails.logger.error { "Invalid player" }
        return
      end

      if Rails.env.development? && current_player["isAI"]
        # AI logic
        exec(game, card, current_player)
        return
      end

      exec(game, card, current_player)
    end

    private

    def choose_ai_card(game, current_player)
      cards = $redis.lrange("game:#{game.uuid}:cards:#{current_player["id"]}", 0, -1)
      cards.sample
    end

    def exec(game, card, current_player)
      # pp game
      # pp current_player
      # puts $redis.keys("game:#{game.uuid}:*")
      # puts "\n" * 3
      # puts "game:#{game.uuid}:cards:#{current_player["id"]}"
      # pp $redis.lrange("game:#{game.uuid}:cards:#{current_player["id"]}", 0, -1)
      sleep 1
      $redis.lpush(
        "game:#{game.uuid}",
        {
          event: "card_played",
          data: {current_player["id"] => card},
          time: Time.current,
        }.to_json
      )
      cards = $redis.lpop("game:#{game.uuid}:cards:#{current_player["id"]}", 7)
      cards.delete(card)
      $redis.lpush("game:#{game.uuid}:cards:#{current_player["id"]}", cards) if cards.present?

      Turbo::StreamsChannel.broadcast_update_to(
        "game_#{game.id}",
        target: "actions_#{current_player["id"]}",
        partial: "frontend/games/actions",
        locals: { game: game, cards:, is_your_turn: false }
      )
      Turbo::StreamsChannel.broadcast_update_to(
        "game_#{game.id}",
        target: "game_state_game_#{game.id}",
        partial: "frontend/games/game_state",
        locals: { game: game }
      )

      current_player_position = $redis.get("game:#{game.uuid}:current_player_position").to_i + 1
      $redis.set("game:#{game.uuid}:current_player_position", current_player_position)
      next_player_position = current_player_position % game.players.size
      next_player = game.players[next_player_position]

      if next_player["isAI"]
        puts "AI turn"
        puts "\n" * 3
        GameJob::PlayCardJob.perform_now(game, choose_ai_card(game, next_player), next_player)
        puts "\n" * 3
        puts "AI turn end"
        return
      end

      $redis.set("game:#{game.uuid}:current_player_position", next_player_position)
      Turbo::StreamsChannel.broadcast_update_to(
        "game_#{game.id}",
        target: "actions_#{next_player["id"]}",
        partial: "frontend/games/actions",
        locals: { game: game, cards:, is_your_turn: true }
      )
      # Turbo::StreamsChannel.broadcast_update_to(
      #   "game_#{game.id}",
      #   target: "self_status_#{current_player["id"]}",
      #   partial: "frontend/games/self_status",
      #   locals: { cucumbers: 1 }
      # )
    end
  end
end