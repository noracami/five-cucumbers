module GameJob
  class PlayCardJob < ApplicationJob
    def perform(game, card_id, current_player_id)
      # Do something later
      # current_player = game.players.find { |p| p["id"] == current_player_id }
      current_player = Games::Player.build_from_game(game: game, player_id: current_player_id)
      current_player.play_card(card_id)
      game.players[game.players.index { current_player.id == _1['id'] }] = current_player.to_json
      game.save!
      Utils::Notify.push_card_played_event(game, current_player, card_id)
    end

    # TODO: Clean up those commented out methods

    # def perform(game, card, current_player)
    #   # Do something later
    #   current_player_position = Utils::Redis.get("game:#{game.uuid}:current_player_position").to_i
    #   if current_player["id"] != game.players[current_player_position]["id"]
    #     puts current_player["id"]
    #     puts game.players[current_player_position]["id"]
    #     Rails.logger.error { "Invalid player" }
    #     return
    #   end

    #   if Rails.env.development? && current_player["isAI"]
    #     # AI logic
    #     exec(game, card, current_player)
    #     return
    #   end

    #   exec(game, card, current_player)
    # end

    private

    def choose_ai_card(game, current_player)
      cards = Utils::Redis.lrange("game:#{game.uuid}:cards:#{current_player["id"]}", 0, -1)
      cards.sample
    end

    def exec(game, card, current_player)
      Utils::Redis.lpush(
        "game:#{game.uuid}",
        {
          event: "card_played",
          data: {current_player["id"] => card},
          time: Time.current,
        }.to_json
      )
      cards = Utils::Redis.lpop("game:#{game.uuid}:cards:#{current_player["id"]}", 7)
      cards.delete(card)
      Utils::Redis.lpush("game:#{game.uuid}:cards:#{current_player["id"]}", cards) if cards.present?

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

      current_player_position = Utils::Redis.get("game:#{game.uuid}:current_player_position").to_i
      current_player_position += 1
      Utils::Redis.set("game:#{game.uuid}:current_player_position", current_player_position)
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

      Utils::Redis.set("game:#{game.uuid}:current_player_position", next_player_position)
      Turbo::StreamsChannel.broadcast_update_to(
        "game_#{game.id}",
        target: "actions_#{next_player["id"]}",
        partial: "frontend/games/actions",
        locals: { game: game, cards:, is_your_turn: true }
      )
    end
  end
end
