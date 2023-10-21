require 'httparty'

class BootsApiClient
  include HTTParty

  BASE_URL = "https://www.boots.com/online/psc/itemStock"
  PARAM_CONSTRAINTS = { store_ids: 10, product_ids: 1}

  class ApiError < StandardError; end

  def check_stock(store_ids, product_ids)

    unless store_ids.length == PARAM_CONSTRAINTS[:store_ids]
      raise ArgumentError, "Need exactly #{PARAM_CONSTRAINTS[:store_ids]} store_ids, received #{store_ids.length}"
    end

    unless product_ids.length == PARAM_CONSTRAINTS[:product_ids]
      raise ArgumentError, "Need exactly #{PARAM_CONSTRAINTS[:product_ids]} product_id, received #{product_ids.length}"
    end

    response = self.class.post(
      BASE_URL,
      headers: {
        'Content-Type' => 'application/json'
      },
      body: {
        storeIdList: store_ids,
        productIdList: product_ids
      }.to_json
    )

    if response.code >= 400
      raise ApiError, "API responded with a #{response.code} status."
    end

    JSON.parse(response.body)
  end
end
