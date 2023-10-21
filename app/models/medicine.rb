class Medicine < ApplicationRecord
  has_many :products, dependent: :destroy
end
