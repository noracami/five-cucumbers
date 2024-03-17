module GameJob
  class PlayCardJob < ApplicationJob
    def perform(game, card_id, current_player_id)
      current_player = Games::Player.build_from_game(game: game, player_id: current_player_id)
      current_player.play_card(card_id)
      game.players[game.players.index { current_player.id == _1['id'] }] = current_player.to_json
      game.save!

      # notify next player to play
      current_player_position = Utils::Redis.get("game:#{game.uuid}:current_player_position").to_i
      players_position = game.wrap_players.map.with_index { |p, i| [i, p.id, p.is_out?] }.reject { _3 }.cycle(2).to_a
      next_player_position = players_position.index { _2 == current_player.id } + 1
      Utils::Redis.set("game:#{game.uuid}:current_player_position", next_player_position[0])

      Utils::Notify.push_card_played_event(game, current_player, card_id)
    end

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
