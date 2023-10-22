class Product < ApplicationRecord
  belongs_to :medicine

  has_many :stock_statuses, dependent: :destroy
end
