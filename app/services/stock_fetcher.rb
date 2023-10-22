class StockFetcher
  def initialize
    @client = BootsApiClient.new
  end

  def fetch_all
    product_ids = Product.pluck(:product_id).map(&:to_s)
    store_ids = Store.pluck(:store_id).map(&:to_s)

    fetch(product_ids, store_ids)
  end

  def fetch(product_ids, store_ids)
    stock_statuses = @client.bulk_check_stock(store_ids:, product_ids:)

    stock_statuses.each do |status|
      status.save!
    end
  end
end
