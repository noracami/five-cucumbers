module Api
  class GamesController < ApplicationController
    skip_before_action :verify_authenticity_token

    def index
      render json: Game.all
    end

    def create
      url = frontend_game_path(rand(1..100))

      Rails.logger.warn { "Game params: #{params}" }
      Rails.logger.warn { "URL: #{url}" }

      render json: { url: },status: 201
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
