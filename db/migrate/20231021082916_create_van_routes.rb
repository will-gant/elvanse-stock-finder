class CreateVanRoutes < ActiveRecord::Migration[6.1]
  def change
    create_table :van_routes do |t|
      t.string :code
      t.references :store, null: false, foreign_key: true

      t.timestamps
    end
  end
end
