module Admin
  class GamesController < ApplicationController
    skip_before_action :verify_authenticity_token, only: %i(create)

    def create
      game = Game.create_mock_game

      redirect_to frontend_game_url(game.uuid, token: 'dev')
    end
  end
end
