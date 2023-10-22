class StockFetcher
  def initialize
    @client = BootsApiClient.new
  end

  def fetch_all
    product_ids = Product.pluck(:id)
    store_ids = Store.pluck(:id)

    fetch(product_ids, store_ids)
  end

  def fetch(product_ids, store_ids)
    stock_statuses = @client.bulk_check_stock(product_ids, store_ids)

    stock_statuses.each do |status|
      status.save!
    end
  end
end
