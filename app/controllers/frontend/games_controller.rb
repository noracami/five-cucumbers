module Frontend
  class GamesController < ApplicationController
    before_action :set_game, only: %i(show previous_room next_room end_game)
    after_action :allow_iframe, only: %i(show)

    def show
      token = params[:token]
      @game.status ||= {}
      @game.status["players"] ||= []
      @game.status["players"] << token
      @game.status["players"] = @game.status["players"].compact.uniq
      @game.save
      session[:token] ||= token
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
      # host = "https://lobby.gaas.waterballsa.tw/api/internal"
      # url = "#{host}/rooms/#{$map[params[:id]][:roomId]}:endGame"

      @game.status ||= {}

      cookies.each do |k, v|
        @game.status["cookies"] ||= {}
        next if @game.status["cookies"].key?(k)
        @game.status["cookies"][k] = v
      end

      @game.save

      # puts "start"
      # puts request.headers['Authorization']
      # puts "done"

      render json: { status: "ok" }
      # send request to end game
      # response = HTTParty.post(url, headers: { "Content-Type" => "application/json" })
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
