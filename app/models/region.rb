class Region < ApplicationRecord
  has_many :areas, dependent: :destroy
end
