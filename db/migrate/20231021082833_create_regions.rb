class CreateRegions < ActiveRecord::Migration[6.1]
  def change
    create_table :regions do |t|
      t.string :name
      t.bigint :region_id, index: true

      t.timestamps
    end
  end
end
