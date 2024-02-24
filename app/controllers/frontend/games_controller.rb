module Frontend
  class GamesController < ApplicationController
    before_action :set_game, only: %i(show previous_room next_room end_game)
    after_action :allow_iframe, only: %i(show)

    def show
      token = params[:token]
      session[:token] ||= token unless token.blank?
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

    def end_game
      host = "https://lobby.gaas.waterballsa.tw/api/internal"
      url = "#{host}/rooms/#{@game.room_id}:endGame"

      # send request to end game
      res = HTTPX.post(
        url,
        headers: {
          "Authorization" => "Bearer #{session[:token]}"
        }
      )

      if res.status.in? 200..299
        render json: { status: "ok" }
      elsif res.body
        Rails.logger.error { res.body }
        render json: { status: "error" }, status: res.status
        # render json: res.body.json, status: res.status
      end
    end

    private
    def allow_iframe
      response.headers.delete "X-Frame-Options"
    end

    def set_game
      @game = Game.find_by!(uuid: params[:id])
    end
  end
end
