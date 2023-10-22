class StockFetcher
  def initialize
    @client = BootsApiClient.new
  end

  def fetch(product_ids, store_ids)
    stock_statuses = @client.bulk_check_stock(product_ids, store_ids)

    stock_statuses.each do |status|
      status.save!
    end
  end
end
