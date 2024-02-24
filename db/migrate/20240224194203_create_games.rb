class CreateGames < ActiveRecord::Migration[7.1]
  def change
    create_table :games do |t|
      t.string :uuid
      t.string :room_id
      t.json :players
      t.json :status

      t.timestamps
    end
  end
end
