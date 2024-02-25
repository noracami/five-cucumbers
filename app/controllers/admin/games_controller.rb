module Admin
  class GamesController < ApplicationController
    def create
      room_id = "dev_#{SecureRandom.base36(13)}"
      players = [{id: SecureRandom.base36(24), nickname: 'Me'}]
      3.times { players << {id: SecureRandom.base36(24), nickname: Faker::Name.first_name} }

      game_id = SecureRandom.base36(8)
      game_id = SecureRandom.base36(8) while Game.exists?(uuid: game_id)

      game = Game.create!(uuid: game_id, room_id: room_id, players: players)

      redirect_to frontend_game_url(game_id)
    end
  end
end
