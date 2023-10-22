require 'httparty'

class BootsApiClient
  include HTTParty

  BASE_URL = 'https://www.boots.com/online/psc/itemStock'
  PERMITTED_STORE_IDS_PER_REQUEST = 10
  PERMITTED_PRODUCT_IDS_PER_REQUEST = 1
  RATE_LIMIT_PER_MINUTE = 4

  class ApiError < StandardError; end

  def bulk_check_stock(store_ids, product_ids)
    validate_request_args(store_ids, product_ids, bulk: true)

    results = []

    store_ids.each_slice(PERMITTED_STORE_IDS_PER_REQUEST) do |store_chunk|
      filled_store_chunk = fill_chunk(store_chunk, store_ids, PERMITTED_STORE_IDS_PER_REQUEST)

      product_ids.each_slice(PERMITTED_PRODUCT_IDS_PER_REQUEST) do |product_chunk|
        filled_product_chunk = fill_chunk(product_chunk, product_ids, PERMITTED_PRODUCT_IDS_PER_REQUEST)

        results << check_stock(filled_store_chunk, filled_product_chunk)
        delay_next_request
      end
    end

    results.flatten.uniq { |stock_status| [stock_status.store_id, stock_status.product_id] }
  end

  def check_stock(store_ids, product_ids)
    validate_request_args(store_ids, product_ids)

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

    raise ApiError, "API responded with a #{response.code} status." if response.code >= 400

    parsed_response = JSON.parse(response.body)
    build_stock_statuses(parsed_response['stockLevels'])
  end

  private

  def build_stock_statuses(stock_levels)
    stock_levels.map do |entry|
      StockStatus.new(
        store_id: entry['storeId'].to_i,
        product_id: entry['productId'].to_i,
        status: entry['stockLevel'],
        checked_at: Time.zone.now
      )
    end
  end

  def fill_chunk(chunk, source_array, permitted_size)
    return chunk if chunk.size >= permitted_size

    to_add = permitted_size - chunk.size
    chunk + source_array.take(to_add)
  end

  def validate_request_args(store_ids, product_ids, bulk: false)
    validate_ids(store_ids, :store_ids, PERMITTED_STORE_IDS_PER_REQUEST, bulk)
    validate_ids(product_ids, :product_ids, PERMITTED_PRODUCT_IDS_PER_REQUEST, bulk)
  end

  def validate_ids(ids, type, permitted, bulk)
    received = ids.length
    is_valid = bulk ? received >= permitted : received == permitted

    raise_argument_error(type, received, permitted, bulk) unless is_valid
  end

  def raise_argument_error(type, received, permitted, bulk)
    condition = bulk ? 'at least' : 'exactly'
    type_string = permitted == 1 ? type.to_s.singularize : type.to_s
    raise ArgumentError, "Need #{condition} #{permitted} #{type_string}, received #{received}"
  end

  def time_between_requests
    60.0 / RATE_LIMIT_PER_MINUTE
  end

  def delay_next_request
    sleep(time_between_requests)
  end
end
