class CreateStores < ActiveRecord::Migration[6.1]
  def change
    create_table :stores do |t|
      t.string :displayname
      t.boolean :isMidnightPharmacy
      t.boolean :isPharmacy
      t.boolean :isPrescriptionStoreCollectionAvailable
      t.string :name
      t.integer :ndsasqm
      t.string :nhsMarket
      t.date :openDate
      t.string :primaryCareOrganisation
      t.bigint :store_id, index: true
      t.references :area, null: false, foreign_key: true
      t.references :manager, null: true, foreign_key: true

      t.timestamps
    end
  end
end
