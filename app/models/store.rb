class Store < ApplicationRecord
  belongs_to :area
  belongs_to :manager, optional: true

  has_one :address, required: false, dependent: :destroy
  has_one :status, required: false, dependent: :destroy
  has_many :van_routes, dependent: :destroy
  has_many :contact_details, dependent: :destroy
  has_many :stock_statuses, dependent: :destroy
end
