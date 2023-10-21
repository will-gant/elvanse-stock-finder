class CreateAreas < ActiveRecord::Migration[6.1]
  def change
    create_table :areas do |t|
      t.string :name
      t.integer :area_id, index: true
      t.references :region, null: false, foreign_key: true

      t.timestamps
    end
  end
end
