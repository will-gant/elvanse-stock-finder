class Region < ApplicationRecord
  has_many :areas, dependent: :destroy
  has_many :stores, through: :areas
end
