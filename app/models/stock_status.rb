class StockStatus < ApplicationRecord
  belongs_to :dose
  belongs_to :store
end
