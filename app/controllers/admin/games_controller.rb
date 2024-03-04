module Admin
  class GamesController < ApplicationController
    skip_before_action :verify_authenticity_token, only: %i(create)

    def create
      game = Game.create_mock_game
      user_info = Games::Player.new(game.players.first).user_info

      redirect_to frontend_game_url(game.uuid, token: Base64.urlsafe_encode64(user_info.to_json))
    end
  end
end
