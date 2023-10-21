class CreateDoses < ActiveRecord::Migration[6.1]
  def change
    create_table :doses do |t|
      t.bigint :concept_id
      t.string :category
      t.decimal :value
      t.string :unit
      t.references :product, null: false, foreign_key: true

      t.timestamps
    end
  end
end
