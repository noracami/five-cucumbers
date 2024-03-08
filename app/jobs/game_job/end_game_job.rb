module GameJob
  class EndGameJob < ApplicationJob
    def perform(game, token: nil)
      if Rails.env.production?
        res = send_end_game_request_to_gaas(game.room_id, token)

        if res.status.in? 200..299
          # game.state_completed!
          game.state_completed!

        elsif res.headers['content-type'] == 'application/json'
          Rails.logger.error { res.json }
          pp "response is json"
          pp res

        else
          Rails.logger.error { res.body.to_s }
          pp "response is not json"
          pp res
        end

      else
        # game.state_completed!
        Utils::Redis.lpush(
          "game:#{game.uuid}",
          {
            event: "game_ended",
            data: {},
            time: Time.current,
          }.to_json
        )
        game_logs = Utils::Redis.lrange("game:#{game.uuid}", 0, -1).to_json
        game.update!(game_logs: game_logs, state: "completed")
        Turbo::StreamsChannel.broadcast_update_to(
          "game_#{game.id}",
          target: "game_state_game_#{game.id}",
          partial: "frontend/games/game_state",
          locals: { game: game, random_num: rand(1..5) }
        )

        # Utils::Notify.push_game_event(game, "game_ended")
      end
    end


    def send_end_game_request_to_gaas(room_id, token)
      host = Rails.configuration.game_as_a_service.backend_host
      url = "#{host}/rooms/#{room_id}:endGame"
      HTTPX.plugin(:auth).bearer_auth(token).post(url, body: '')
    end
  end
end
