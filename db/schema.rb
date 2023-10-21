# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_10_21_104335) do

  create_table "addresses", charset: "utf8mb4", force: :cascade do |t|
    t.string "administrativeArea"
    t.string "countryCode"
    t.string "county"
    t.string "locality"
    t.string "postcode"
    t.string "street"
    t.string "town"
    t.bigint "store_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["store_id"], name: "index_addresses_on_store_id"
  end

  create_table "areas", charset: "utf8mb4", force: :cascade do |t|
    t.string "name"
    t.integer "area_id"
    t.bigint "region_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["area_id"], name: "index_areas_on_area_id"
    t.index ["region_id"], name: "index_areas_on_region_id"
  end

  create_table "contact_details", charset: "utf8mb4", force: :cascade do |t|
    t.string "phone"
    t.bigint "store_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["store_id"], name: "index_contact_details_on_store_id"
  end

  create_table "doses", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "concept_id"
    t.string "category"
    t.decimal "value", precision: 10
    t.string "unit"
    t.bigint "product_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["product_id"], name: "index_doses_on_product_id"
  end

  create_table "grid_locations", charset: "utf8mb4", force: :cascade do |t|
    t.float "latitude"
    t.float "longitude"
    t.string "propertyEasting"
    t.string "propertyNorthing"
    t.bigint "address_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["address_id"], name: "index_grid_locations_on_address_id"
  end

  create_table "managers", charset: "utf8mb4", force: :cascade do |t|
    t.string "email"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "medicines", charset: "utf8mb4", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "producers", charset: "utf8mb4", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "products", charset: "utf8mb4", force: :cascade do |t|
    t.string "name"
    t.bigint "medicine_id", null: false
    t.bigint "producer_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["medicine_id"], name: "index_products_on_medicine_id"
    t.index ["producer_id"], name: "index_products_on_producer_id"
  end

  create_table "regions", charset: "utf8mb4", force: :cascade do |t|
    t.string "name"
    t.integer "region_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["region_id"], name: "index_regions_on_region_id"
  end

  create_table "statuses", charset: "utf8mb4", force: :cascade do |t|
    t.integer "code"
    t.string "text"
    t.bigint "store_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["store_id"], name: "index_statuses_on_store_id"
  end

  create_table "stock_statuses", charset: "utf8mb4", force: :cascade do |t|
    t.string "status"
    t.datetime "checked_at"
    t.bigint "dose_id", null: false
    t.bigint "store_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["dose_id"], name: "index_stock_statuses_on_dose_id"
    t.index ["store_id"], name: "index_stock_statuses_on_store_id"
  end

  create_table "stores", charset: "utf8mb4", force: :cascade do |t|
    t.string "displayname"
    t.string "isMidnightPharmacy"
    t.string "isPharmacy"
    t.boolean "isPrescriptionStoreCollectionAvailable"
    t.string "name"
    t.integer "ndsasqm"
    t.string "nhsMarket"
    t.date "openDate"
    t.string "primaryCareOrganisation"
    t.integer "store_id"
    t.bigint "area_id", null: false
    t.bigint "manager_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["area_id"], name: "index_stores_on_area_id"
    t.index ["manager_id"], name: "index_stores_on_manager_id"
    t.index ["store_id"], name: "index_stores_on_store_id"
  end

  create_table "van_routes", charset: "utf8mb4", force: :cascade do |t|
    t.string "code"
    t.bigint "store_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["store_id"], name: "index_van_routes_on_store_id"
  end

  add_foreign_key "addresses", "stores"
  add_foreign_key "areas", "regions"
  add_foreign_key "contact_details", "stores"
  add_foreign_key "doses", "products"
  add_foreign_key "grid_locations", "addresses"
  add_foreign_key "products", "medicines"
  add_foreign_key "products", "producers"
  add_foreign_key "statuses", "stores"
  add_foreign_key "stock_statuses", "doses"
  add_foreign_key "stock_statuses", "stores"
  add_foreign_key "stores", "areas"
  add_foreign_key "stores", "managers"
  add_foreign_key "van_routes", "stores"
end
