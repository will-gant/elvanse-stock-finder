module MockApiHelper
  def mock_boots_api_response_body(store_ids:, product_ids:)
    stock_levels = store_ids.map.with_index do |store_id, index|
      {
        "storeId" => store_id.to_s,
        "productId" => product_ids.empty? ? "" : product_ids[index % product_ids.size].to_s,
        "stockLevel" => ["R", "G", "Y"].sample
      }
    end

    {
      "stockLevels" => stock_levels,
      "rejectedFilters" => nil
    }.to_json
  end
end
