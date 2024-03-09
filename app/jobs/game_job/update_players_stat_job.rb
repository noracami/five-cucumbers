module GameJob
  class UpdatePlayersStatJob < ApplicationJob
    def perform(game_id: nil)
      Utils::Notify.update_players_stat(Game.find(game_id))
    end
  end
end
