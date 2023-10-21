class Address < ApplicationRecord
  belongs_to :store

  has_one :grid_location, required: false, dependent: :destroy
end
