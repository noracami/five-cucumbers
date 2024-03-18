class CreateGameRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :game_records do |t|
      t.integer :game_id
      t.string :winner_id
      t.string :winner_nickname
      t.integer :rounds
      t.integer :player_number
      t.datetime :start_time

      t.timestamps
    end
  end
end
