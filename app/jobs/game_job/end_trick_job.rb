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
        # 1. find who won the round
        card_wind_the_trick = Utils::Redis.largest_card_in_the_trick(game.uuid)
        card_id = card_wind_the_trick.id
        winner = game.wrap_players.find { |p| p.card_played == card_id }
        # 2. determine how many cucumbers the winner will get
        cucumbers = card_wind_the_trick.cucumbers
        cucumbers *= 2 if Utils::Redis.read_trick(game.uuid).map(&:numbers).include?(1)
        # 3. save the game
        winner.cucumbers += cucumbers
        if winner.cucumbers > 5
          winner.cucumbers = 5
          winner.is_out = true
        end
        winner.save

        game.reload
        players = game.wrap_players
        players.each { |p| p.card_played = nil }
        game.players = players.map(&:to_json)
        game.save

        if game.has_winner?
          game.state_completed!
          GameJob::ShowEndJob.perform_later(game.id)
          GameRecord.create_game_record(game)
        else
          GameJob::PrepareRoundJob.perform_now(game.id, last_trick_winner_id: winner.id)
        end

        return
      end

      game_notifier.update_game_event_logs
      game.wrap_players.each do |player|
        game_notifier.update_player_actions(player).update_players_stat(player.id)
      end

      game.reload
      AiJobs::AutoMoveJob.perform_later(game.id) if game.wrap_players.find { |p| p.id == game.current_player_id }.is_ai?
    end
  end
end
