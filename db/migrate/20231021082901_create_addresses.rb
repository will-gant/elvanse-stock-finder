class CreateAddresses < ActiveRecord::Migration[6.1]
  def change
    create_table :addresses do |t|
      t.string :administrativeArea
      t.string :countryCode
      t.string :county
      t.string :locality
      t.string :postcode
      t.string :street
      t.string :town
      t.references :store, null: false, foreign_key: true

      t.timestamps
    end
  end
end
