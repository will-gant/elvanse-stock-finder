class CreateContactDetails < ActiveRecord::Migration[6.1]
  def change
    create_table :contact_details do |t|
      t.string :phone
      t.references :store, null: false, foreign_key: true

      t.timestamps
    end
  end
end
