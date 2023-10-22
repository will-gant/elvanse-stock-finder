class CreateStockStatuses < ActiveRecord::Migration[6.1]
  def change
    create_table :stock_statuses do |t|
      t.string :status
      t.datetime :checked_at
      t.references :product, null: false, foreign_key: true
      t.references :store, null: false, foreign_key: true

      t.timestamps
    end
  end
end
