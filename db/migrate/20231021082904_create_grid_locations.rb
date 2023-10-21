class CreateGridLocations < ActiveRecord::Migration[6.1]
  def change
    create_table :grid_locations do |t|
      t.float :latitude
      t.float :longitude
      t.string :propertyEasting
      t.string :propertyNorthing
      t.references :address, null: false, foreign_key: true

      t.timestamps
    end
  end
end
