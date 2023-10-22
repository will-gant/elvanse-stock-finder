module SpecHelpers
  def mock_boots_api_response_body(store_ids:, product_ids:)
    stock_levels = store_ids.map.with_index do |store_id, index|
      {
        "storeId" => store_id.to_s,
        "productId" => product_ids.empty? ? "" : product_ids[index % product_ids.size].to_s,
        "stockLevel" => "G"
      }
    end

    {
      "stockLevels" => stock_levels,
      "rejectedFilters" => nil
    }.to_json
  end

  def fake_store_ids(n)
    (1..9999).to_a.sample(n)
  end

  def fake_product_ids(n)
    ids = Set.new
    while ids.size < n
      id = SecureRandom.random_number(10**17)
      next if id < 10**16
      ids << id
    end
    ids.to_a
  end

  def random_not_divisible_by(n:, limit: Float::INFINITY)
    return rand(2..limit) if n == 1

    loop do
      random_number = rand(1..limit)
      return random_number unless random_number % n == 0
    end
  end
end
