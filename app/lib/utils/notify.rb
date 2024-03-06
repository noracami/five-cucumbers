module Utils
  class Notify
    def self.push_player_joined_event(game, player_id, event = 'player_joined')
      message = {
        event: event,
        data: { player_id: player_id },
        time: Time.current
      }

      Utils::Redis.lpush("game:#{game.uuid}:events", message.to_json)

      Turbo::StreamsChannel.broadcast_update_to(
        "game_#{game.id}",
        target: "game_events_game_#{game.id}",
        partial: "frontend/games/game_events",
        locals: {
          game_events: Utils::Redis.last_10_game_events(game.uuid),
          game: game
        }
      )
    end

    def self.update_players_stat(game)
      sleep 0.5 while game.players.size < 2

      game.players.each do |player|
        Turbo::StreamsChannel.broadcast_update_to(
          "game_#{game.id}",
          target: "game_players_#{player["id"]}",
          partial: "frontend/games/game_players",
          locals: {
            players: game.players,
            current_player_id: player["id"]
          }
        )
      end
    end

    def self.push_game_started_event(game)
      message = {
        event: 'game_started',
        game: game.to_json
      }
      Utils::Redis.lpush(game.id, message.to_json)
    end

    def self.push_game_ended_event(game)
      message = {
        event: 'game_ended',
        game: game.to_json
      }
      Utils::Redis.lpush(game.id, message.to_json)
    end

    def self.push_game_state_changed_event(game)
      message = {
        event: 'game_state_changed',
        game: game.to_json
      }
      Utils::Redis.lpush(game.id, message.to_json)
    end
  end
end
