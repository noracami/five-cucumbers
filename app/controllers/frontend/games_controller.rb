module Frontend
  class GamesController < ApplicationController
    skip_before_action :verify_authenticity_token, only: %i(show next_state end_game)

    before_action :set_game, only: %i(show play_card next_state end_game)
    after_action :allow_iframe, only: %i(show)

    def index
      @games = Game.playing.order(updated_at: :desc).limit(10)
    end

    def show
      if params[:token].present?
        if Rails.env.development?
          user_info = JSON.parse(Base64.urlsafe_decode64(params[:token]))
          session[:user_info] = {}
          user_info.each { |k, v| session[:user_info][k.to_sym] = v }
          $redis.lpush(
            "game:#{@game.uuid}",
            {
              event: "user_joined(local)",
              data: {user: "local"},
              time: Time.current,
            }.to_json
          )
        elsif Rails.env.production? && Auth0Client.validate_token(params[:token]).error.nil?

          # save token in session
          session[:token] = params[:token]
          # save user in session
          # user info is fetch at GET gaas/users/me
          url = "#{Rails.configuration.game_as_a_service.backend_host}/users/me"
          res = HTTPX.plugin(:auth).bearer_auth(session[:token]).get(url)

          if res.status.in? 200..299
            session[:user_info] = {}
            res.json.each { |k, v| session[:user_info][k.to_sym] = v }
            $redis.lpush(
              "game:#{@game.uuid}",
              {
                event: "user_joined",
                data: {user: session[:user_info][:nickname]},
                time: Time.current,
              }.to_json
            )
          else
            Rails.logger.error { res.body.to_s }
          end
        end

        redirect_to frontend_game_path
      end
    end

    def play_card
      card = params[:card]
      # @game.play_card(card)
      cards = $redis.lpop("game:#{@game.uuid}:cards:#{session[:user_info]["id"]}", 7)
      if (card_idx = cards.index(card))
        cards.delete_at(card_idx)
        $redis.lpush(
          "game:#{@game.uuid}",
          {
            event: "card_played",
            data: {session[:user_info]["id"] => card},
            time: Time.current,
          }.to_json
        )
        $redis.lpush("game:#{@game.uuid}:cards:#{session[:user_info]["id"]}", cards) if cards.present?
        Turbo::StreamsChannel.broadcast_update_to(
          "game_#{@game.id}",
          target: "actions_#{session[:user_info]["id"]}",
          partial: "frontend/games/actions",
          locals: { game: @game, cards: }
        )
      else
        $redis.lpush(
          "game:#{@game.uuid}",
          {
            event: "card_played",
            data: {session[:user_info]["id"] => "invalid"},
            time: Time.current,
          }.to_json
        )
      end
      Turbo::StreamsChannel.broadcast_update_to(
        "game_#{@game.id}",
        target: "game_state_game_#{@game.id}",
        partial: "frontend/games/game_state",
        locals: { game: @game }
      )
    end

    def next_state
      return render json: { status: "no next state" } if @game.state == "completed"

      @game.update!(state: Game.states[@game.state] + 1)

      if @game.state == "completed" && Rails.env.production?
        # send request to end game
        send_end_game_request_to_gaas
        return render json: { status: "ok" }
      end

      Turbo::StreamsChannel.broadcast_update_to(
        "game_#{@game.id}",
        target: "game_state_#{@game.id}",
        partial: "frontend/games/game_state",
        locals: { game: @game, random_num: rand(1..5) }
      )
      # redirect_to frontend_game_path
      render json: { status: "ok" }, status: 303
    end

    def end_game
      if Rails.env.production?

        # send request to end game
        res = send_end_game_request_to_gaas

        if res.status.in? 200..299
          # @game.state_completed!

          # render json: { status: "ok" }
        elsif res.headers['content-type'] == 'application/json'
          Rails.logger.error { res.json }
          pp "response is json"
          pp res
          return render json: { status: res.json }, status: res.status
        else
          Rails.logger.error { res.body.to_s }
          pp "response is not json"
          pp res
          return render json: { status: "error" }, status: res.status
        end
      end

      @game.state_completed!
      $redis.lpush(
        "game:#{@game.uuid}",
        {
          event: "game_ended",
          data: {},
          time: @game.updated_at,
        }.to_json
      )
      @game.update!(game_logs: $redis.lrange("game:#{@game.uuid}", 0, -1).to_json)
      Turbo::StreamsChannel.broadcast_update_to(
        "game_#{@game.id}",
        target: "game_state_game_#{@game.id}",
        partial: "frontend/games/game_state",
        locals: { game: @game, random_num: rand(1..5) }
      )
      redirect_to frontend_game_path
    end

    private

    def allow_iframe
      response.headers.delete "X-Frame-Options"
    end

    def set_game
      @game = Game.find_by!(uuid: params[:id])
    end

    def send_end_game_request_to_gaas
      host = Rails.configuration.game_as_a_service.backend_host
      url = "#{host}/rooms/#{@game.room_id}:endGame"

      Rails.logger.warn { "token: #{session[:token]}" }
      pp session.keys

      HTTPX.plugin(:auth).bearer_auth(session[:token]).post(url, body: '')
    end
  end
end
