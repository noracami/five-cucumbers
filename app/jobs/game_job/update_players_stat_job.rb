module GameJob
  class UpdatePlayersStatJob < ApplicationJob
    def perform(game)
      Utils::Notify.update_players_stat(game)
    end
  end
end
