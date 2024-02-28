module Api
  class GamesController < ApplicationController
    skip_before_action :verify_authenticity_token

    def index
      render json: Game.all
    end

    def create
      room_id = params.fetch("roomId")
      players = params.fetch("players")

      game_id = SecureRandom.base36(8)
      game_id = SecureRandom.base36(8) while Game.exists?(uuid: game_id)

      game = Game.create!(uuid: game_id, room_id: room_id, players: players)

      $redis.lpush(
        "game:#{game_id}",
        {
          event: "game_created",
          data: {
            game_id: game_id,
            room_id: room_id,
            players: players
          },
          time: game.created_at,
          ex: 1.hour.from_now
        }.to_json
      )

      game.deal_cards

      render json: { url: frontend_game_url(game_id) }, status: 201
    end

    private

    def game_params
      # params.require(:game).permit(:name, :description, :price)
    end
  end
end
