class Store < ApplicationRecord
  belongs_to :area
  belongs_to :manager, optional: true

  has_one :address, required: false
  has_one :status, required: false
  has_many :van_routes
  has_many :contact_details
end
