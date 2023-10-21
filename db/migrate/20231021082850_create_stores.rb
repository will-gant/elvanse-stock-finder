class CreateStores < ActiveRecord::Migration[6.1]
  def change
    create_table :stores do |t|
      t.string :displayname
      t.string :isMidnightPharmacy
      t.string :isPharmacy
      t.boolean :isPrescriptionStoreCollectionAvailable
      t.string :name
      t.integer :ndsasqm
      t.string :nhsMarket
      t.date :openDate
      t.string :primaryCareOrganisation
      t.integer :store_id, index: true
      t.references :area, null: false, foreign_key: true
      t.references :manager, null: true, foreign_key: true

      t.timestamps
    end
  end
end
