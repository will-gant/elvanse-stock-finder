class CreateStatuses < ActiveRecord::Migration[6.1]
  def change
    create_table :statuses do |t|
      t.integer :code
      t.string :text
      t.references :store, null: false, foreign_key: true

      t.timestamps
    end
  end
end
