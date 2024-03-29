module Utils
  class Notify
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :game_uuid, :string
    attribute :game_id, :integer
    attribute :game

    #
    # @param game [Game] The game object
    def initialize(game)
      super(game_uuid: game.uuid, game_id: game.id, game: game)
    end

    def inspect
      "Game Notify: #{game_uuid}, Game ID: #{game_id}"
    end

    def update_player_actions(player)
      Turbo::StreamsChannel.broadcast_update_to(
        "game_#{game_id}",
        target: "actions_#{player.id}",
        partial: "frontend/games/actions",
        locals: { game:, current_player: player }
      )
      self
    end

    def update_players_stat(player_id)
      Turbo::StreamsChannel.broadcast_update_to(
        "game_#{game_id}",
        target: "game_players_#{player_id}",
        partial: "frontend/games/game_players",
        locals: { game:, current_player_id: player_id }
      )
      self
    end

    def update_game_event_logs
      Turbo::StreamsChannel.broadcast_update_to(
        "game_#{game_id}",
        target: "game_events_game_#{game_id}",
        partial: "frontend/games/game_events",
        locals: { game_events: Utils::Redis.last_10_game_events(game_uuid), game: game }
      )
      self
    end

    def update_game_rounds
      Turbo::StreamsChannel.broadcast_update_to(
        "game_#{game_id}",
        target: "game_rounds_game_#{game_id}",
        partial: "frontend/games/game_rounds",
        locals: { game: game, game_status: game.current_rounds }
      )
      self
    end

    def push_error_event(current_player_id, message)
      notice_id = SecureRandom.base36
      Turbo::StreamsChannel.broadcast_prepend_to(
        "game_#{game_id}",
        partial: "frontend/games/notice",
        target: "actions_#{current_player_id}",
        locals: { notice_id:, message: }
      )

      sleep 1

      Turbo::StreamsChannel.broadcast_remove_to(
        "game_#{game_id}",
        target: notice_id
      )
    end

    def push_it_is_turn_for_player_event(player_nickname, event = 'system_message')
      return unless ENV.fetch('SHOW_WHOSE_TURN_IN_EVENT', false)

      message = {
        event: event,
        data: "It's #{player_nickname}'s turn.",
        time: Time.current
      }
      Utils::Redis.lpush("game:#{game_uuid}:events", message.to_json)
    end

    def push_card_played_event(current_player, card, event = 'system_message')
      message = {
        event: event,
        data: "#{current_player.nickname} played #{card}.",
        time: Time.current
      }
      Utils::Redis.lpush("game:#{game_uuid}:events", message.to_json)
    end

    def push_game_ended_event
      message = {
        event: 'game_ended',
        time: Time.current
      }
      Utils::Redis.lpush("game:#{game.uuid}:events", message.to_json)
    end

    def update_played_cards_on_table(card_numbers)
      Turbo::StreamsChannel.broadcast_append_to(
        "game_#{game_id}",
        target: "played-cards-on-table",
        partial: "frontend/games/v1/played_card",
        locals: { number: card_numbers }
      )
      self
    end

    def self.push_player_joined_event(game, player, event = 'player_joined')
      message = {
        event: event,
        data: player,
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
      game.wrap_players.each do |player|
        Turbo::StreamsChannel.broadcast_update_to(
          "game_#{game.id}",
          target: "game_players_#{player.id}",
          partial: "frontend/games/game_players",
          locals: {
            game: game,
            current_player_id: player.id
          }
        )
      end
    end

    def self.push_card_played_event(game, current_player, card)
      message = {
        event: 'card_played',
        data: "#{current_player.nickname} played (##{card})",
        time: Time.current
      }

      Utils::Redis.lpush("game:#{game.uuid}:events", message.to_json)

      # update event logs seen by all players
      Turbo::StreamsChannel.broadcast_update_to(
        "game_#{game.id}",
        target: "game_events_game_#{game.id}",
        partial: "frontend/games/game_events",
        locals: {
          game_events: Utils::Redis.last_10_game_events(game.uuid),
          game: game
        }
      )

      # update player stats seen by all players
      game.wrap_players.each do |player|
        Turbo::StreamsChannel.broadcast_update_to(
          "game_#{game.id}",
          target: "game_players_#{player.id}",
          partial: "frontend/games/game_players",
          locals: {
            game:,
            current_player_id: player.id,
          }
        )
      end

      # update the player's available actions seen by the player
      Turbo::StreamsChannel.broadcast_update_to(
        "game_#{game.id}",
        target: "actions_#{current_player.id}",
        partial: "frontend/games/actions",
        locals: {
          game:,
          current_player:,
          is_your_turn: false
        }
      )
    end

    def self.push_game_ended_event(game)
      new(game).push_game_ended_event
    end

    # def update_redis_logs()
    #   Turbo::StreamsChannel.broadcast_update_to(
    #     "game_#{game_id}",
    #     target: "game_events_game_#{game_id}",
    #     partial: "frontend/games/game_events",
    #     locals: { game_events: Utils::Redis.last_10_game_events(game_uuid), game: game }
    #   )
    # end

    # def self.push_generic_event(game, event_name = 'generic_event', data = {})
    #   message = {
    #     event: event_name,
    #     data: data,
    #     time: Time.current
    #   }
    #   Utils::Redis.lpush("game:#{game.uuid}:events", message.to_json)
    #   Turbo::StreamsChannel.broadcast_update_to(
    #     "game_#{game.id}",
    #     target: "game_events_game_#{game.id}",
    #     partial: "frontend/games/game_events",
    #     locals: {
    #       game_events: Utils::Redis.last_10_game_events(game.uuid),
    #       game: game
    #     }
    #   )
    # end

    # def self.push_game_started_event(game)
    #   message = {
    #     event: 'game_started',
    #     game: game.to_json
    #   }
    #   Utils::Redis.lpush(game.id, message.to_json)
    # end

    # def self.push_game_state_changed_event(game)
    #   message = {
    #     event: 'game_state_changed',
    #     game: game.to_json
    #   }
    #   Utils::Redis.lpush(game.id, message.to_json)
    # end
  end
end
