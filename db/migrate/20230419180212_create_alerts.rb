class CreateAlerts < ActiveRecord::Migration[7.0]
  def change
    create_table :alerts do |t|
      t.integer :user_id, null: false
      t.string :coin_symbol
      t.integer :target_price
      t.integer :status

      t.timestamps
    end
    add_foreign_key :alerts, :users, column: :user_id, primary_key: "id"
  end

  def down
    drop_table :alerts
  end
end
