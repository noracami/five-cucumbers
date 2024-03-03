module Api
  class GamesController < ApplicationController
    skip_before_action :verify_authenticity_token

    def index
      render json: Game.all
    end

    def create
      room_id = params.fetch("roomId")
      players = params.fetch("players")

      game = Game.create!(room_id: room_id, players: players)

      render json: { url: frontend_game_url(game.uuid) }, status: 201
    end
  end
end
