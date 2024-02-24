module Api
  class GamesController < ApplicationController
    def index
      render json: Game.all
    end

    def create
      Rails.logger.warn "Game params: #{params}"
      render json: { url: frontend_game_path(rand(1..100)) },status: 201
      # game = Game.new(game_params)
      # if game.save
      #   render json: game
      # else
      #   render json: game.errors, status: 422
      # end
    end

    private

    def game_params
      # params.require(:game).permit(:name, :description, :price)
    end
  end
end
