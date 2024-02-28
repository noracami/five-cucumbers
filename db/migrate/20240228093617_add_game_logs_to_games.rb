class AddGameLogsToGames < ActiveRecord::Migration[7.1]
  def change
    add_column :games, :game_logs, :text
  end
end
