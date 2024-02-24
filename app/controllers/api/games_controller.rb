module Api
  class GamesController < ApplicationController
    skip_before_action :verify_authenticity_token

    def index
      render json: Game.all
    end

    def create
      room_id = params.require(:game).fetch("roomId")
      players = params.require(:game).fetch("players")

      game_id = SecureRandom.base36(8)
      game_id = SecureRandom.base36(8) if $map.key?(game_id)

      $map[game_id] = {
        roomId: room_id,
        players: players
      }

      render json: { url: frontend_game_url(game_id) }, status: 201
    end

    private

    def game_params
      # params.require(:game).permit(:name, :description, :price)
    end
  end
end
