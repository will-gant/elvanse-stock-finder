class Producer < ApplicationRecord
  has_many :products, dependent: :destroy
end
