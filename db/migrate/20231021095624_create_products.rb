class CreateProducts < ActiveRecord::Migration[6.1]
  def change
    create_table :products do |t|
      t.string :dose
      t.bigint :product_id
      t.references :medicine, null: false, foreign_key: true

      t.timestamps
    end
  end
end
