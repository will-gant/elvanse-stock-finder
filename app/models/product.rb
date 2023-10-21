class Product < ApplicationRecord
  belongs_to :medicine
  belongs_to :producer
  has_many :doses, dependent: :destroy
end
