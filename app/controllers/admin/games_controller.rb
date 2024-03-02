module Admin
  class GamesController < ApplicationController
    skip_before_action :verify_authenticity_token, only: %i(create)

    def create
      room_id = "dev_#{SecureRandom.base36(13)}"
      me = {id: SecureRandom.base36(24), nickname: 'Me', email: 'dev@cucumbers.io'}
      user_info = {nickname: me[:nickname], email: me[:email], id: me[:id]}
      players = [{id: me[:id], nickName: me[:nickname]}]
      3.times { players << {id: SecureRandom.base36(24), nickName: Faker::Name.first_name, isAI: true} }

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

      redirect_to frontend_game_url(game_id, token: Base64.urlsafe_encode64(user_info.to_json))
    end
  end
end
