class Area < ApplicationRecord
  belongs_to :region
  
  has_many :stores, dependent: :destroy
end
