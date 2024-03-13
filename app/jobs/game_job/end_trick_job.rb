module GameJob
  class EndTrickJob < ApplicationJob
    def perform(game)
      game_notifier = Utils::Notify.new(game)
      game.wrap_players.each do |player|
        game_notifier.push_error_event(player.id, "event resolve trick triggered")
      end

      # 1. Did 7 tricks played?
      if game.how_many_tricks_played != 7
        # 2.1  No, then decide the next player
        card_id = Utils::Redis.largest_card_in_the_trick(game.uuid).id
        winner = game.wrap_players.find { |p| p.card_played == card_id }
        players = game.wrap_players
        players.each { |p| p.card_played = nil }
        game.players = players.map(&:to_json)
        game.save

        game.wrap_players.each do |player|
          game_notifier.push_error_event(player.id, "Next player is #{winner.nickname}")
        end

        game.decide_player_order(winner.id)
        Utils::Redis.initialize_trick(game.uuid, game.how_many_tricks_played + 1)
      else
        # 2.2  yes, then solve the round
        game.wrap_players.each do |player|
          game_notifier.push_error_event(player.id, "event resolve round triggered")
        end
        raise "Not implemented"
      end

      game_notifier = Utils::Notify.new(game)
      game_notifier.update_game_event_logs
      game.wrap_players.each do |player|
        game_notifier.update_player_actions(player).update_players_stat(player.id)
      end
    end
  end
end
