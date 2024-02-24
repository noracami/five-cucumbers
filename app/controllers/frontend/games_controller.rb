module Frontend
  class GamesController < ApplicationController
    after_action :allow_iframe, only: %i(show)

    def show
      @data = $map[params[:id]]
      Rails.logger.warn { "Frontend::GamesController#show #{params[:id]}" }
    end

    def previous_room
      $map[params[:id]][:previous_room] ||= 0
      $map[params[:id]][:previous_room] += 1
      redirect_to frontend_game_path
    end

    def next_room
      $map[params[:id]][:next_room] ||= 0
      $map[params[:id]][:next_room] += 1
      redirect_to frontend_game_path
    end

    def end_game
      # host = "https://lobby.gaas.waterballsa.tw/api/internal"
      # url = "#{host}/rooms/#{$map[params[:id]][:roomId]}:endGame"

      cookies.each do |k, v|
        $map[params[:id]][:cookies] ||= {}
        next if $map[params[:id]][:cookies].key?(k)
        $map[params[:id]][:cookies][k] = v
      end

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
  end
end
