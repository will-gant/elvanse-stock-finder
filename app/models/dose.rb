class Dose < ApplicationRecord
  belongs_to :product

  has_many :stock_statuses, dependent: :destroy
end
