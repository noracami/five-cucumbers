module Frontend
  class GamesController < ApplicationController
    before_action :set_game, only: %i(show previous_room next_room next_state end_game)
    after_action :allow_iframe, only: %i(show)

    def index
      @games = Game.playing.order(updated_at: :desc).limit(10)
    end

    def show
      if params[:token] && Auth0Client.validate_token(params[:token]).error.nil?
        # save token in session
        session[:token] = params[:token]

        # save user in session
        # user info is fetch at GET gaas/users/me
        url = "#{Rails.configuration.game_as_a_service.backend_host}/users/me"
        res = HTTPX.plugin(:auth).bearer_auth(session[:token]).get(url)

        if res.status.in? 200..299
          session[:user_info] = {}
          res.json.each { |k, v| session[:user_info][k.to_sym] = v }
        else
          Rails.logger.error { res.body.to_s }
        end
      end
    end

    def previous_room
      @game.status ||= {}
      @game.status["previous_room"] ||= 0
      @game.status["previous_room"] += 1
      @game.save
      redirect_to frontend_game_path
    end

    def next_room
      @game.status ||= {}
      @game.status["next_room"] ||= 0
      @game.status["next_room"] += 1
      @game.save
      redirect_to frontend_game_path
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
        target: "game_#{@game.id}",
        partial: "frontend/games/game",
        locals: { game: @game }
      )
      render json: { status: "ok" }
    end

    def end_game
      if Rails.env.production?

        # send request to end game
        res = send_end_game_request_to_gaas

        if res.status.in? 200..299
          @game.state_completed!

          render json: { status: "ok" }
        elsif res.headers['content-type'] == 'application/json'
          Rails.logger.error { res.json }
          render json: { status: res.json }, status: res.status
        else
          Rails.logger.error { res.body.to_s }
          render json: { status: "error" }, status: res.status
        end
      else
        @game.state_completed!
        Turbo::StreamsChannel.broadcast_update_to("game_#{@game.id}",
                                                  target: "game_#{@game.id}",
                                                  partial: "frontend/games/game",
                                                  locals: { game: @game })
        render json: { status: "ok" }
      end
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

      HTTPX.plugin(:auth).bearer_auth(session[:token]).post(url, body: '')
    end
  end
end
