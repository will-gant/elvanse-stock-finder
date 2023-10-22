require 'httparty'
require 'logger'

class StockFetcher
  include HTTParty

  BASE_URL = 'https://www.boots.com/online/psc/itemStock'
  PERMITTED_STORE_IDS_PER_REQUEST = 10
  PERMITTED_PRODUCT_IDS_PER_REQUEST = 1
  RATE_LIMIT_PER_MINUTE = 6

  class StockFetcherError < StandardError; end

  def initialize
    @logger = ::Logger.new(STDOUT)
  end

  def fetch_all
    product_ids = Product.pluck(:product_id).map(&:to_s)
    store_ids = Store.pluck(:store_id).map(&:to_s)

    fetch(product_ids, store_ids)
  end

  def products_for_dose(medicine, dose)
    Product.where(medicine: medicine, dose: dose)
  end

  def fetch_regions(*regions)
    products_ids = Product.pluck(:product_id).map(&:to_s)
    Region.where(name: regions).each do |region|
      store_ids = region.stores.pluck(:store_id).map(&:to_s)
      fetch(products_ids, store_ids)
    end
  end

  def fetch(product_ids, store_ids)
    stock_statuses = bulk_check_stock(store_ids:, product_ids:)
  end

  def bulk_check_stock(store_ids:, product_ids:)
    log_start_of_bulk_check(store_ids, product_ids)
    validate_request_args(store_ids, product_ids, bulk: true)

    results = []

    store_ids.each_slice(PERMITTED_STORE_IDS_PER_REQUEST).with_index do |store_chunk, index|
      log_processing_of_store_chunk(index)
      filled_store_chunk = fill_chunk(store_chunk, store_ids, PERMITTED_STORE_IDS_PER_REQUEST)

      results.concat(process_products_for_store_chunk(filled_store_chunk, product_ids))

      log_end_of_store_chunk_processing(index)
    end

    log_end_of_bulk_check(results)

    results.uniq { |stock_status| [stock_status.store_id, stock_status.product_id] }
  end

  def check_stock(store_ids:, product_ids:)
    log_checking_stock(store_ids, product_ids)
    validate_request_args(store_ids, product_ids)

    response = send_stock_request(store_ids, product_ids)
    handle_invalid_response!(response)

    parsed_response = parse_response(response)
    validate_parsed_response!(parsed_response)

    log_successful_retrieval(store_ids, product_ids)
    build_stock_statuses(parsed_response['stockLevels'])
  end

  private

  def build_stock_statuses(stock_levels)
    stock_levels.map do |entry|
      product = Product.find_by(product_id: entry['productId'].to_i)
      raise StockFetcherError, "Product ID #{entry['productId']} not found in database." if product.nil?

      store = Store.find_by(store_id: entry['storeId'].to_i)
      raise StockFetcherError, "Store ID #{entry['storeId']} not found in database." if store.nil?

      StockStatus.new(
        store:,
        product:,
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

  def log_start_of_bulk_check(store_ids, product_ids)
    @logger.info "Starting bulk stock check for #{store_ids.length} stores and #{product_ids.length} products."
  end

  def log_processing_of_store_chunk(index)
    @logger.info "Processing store chunk #{index + 1}..."
  end

  def process_products_for_store_chunk(filled_store_chunk, product_ids)
    chunk_results = []

    product_ids.each_slice(PERMITTED_PRODUCT_IDS_PER_REQUEST) do |product_chunk|
      log_fetching_product_chunk(product_chunk)

      filled_product_chunk = fill_chunk(product_chunk, product_ids, PERMITTED_PRODUCT_IDS_PER_REQUEST)
      results_for_chunk = check_stock(store_ids: filled_store_chunk, product_ids: filled_product_chunk)
      chunk_results.concat(results_for_chunk)
      save_statuses(results_for_chunk)

      log_end_of_product_chunk_processing(product_chunk)
      delay_next_request
    end

    chunk_results
  end

  def log_fetching_product_chunk(product_chunk)
    @logger.info "Fetching stock status for product IDs #{product_chunk}..."
  end

  def save_statuses(chunk_results)
    chunk_results.each do |status|
      status.save!
    end
  end

  def log_end_of_product_chunk_processing(product_chunk)
    @logger.info "Finished processing product chunk for product IDs #{product_chunk}."
  end

  def log_end_of_store_chunk_processing(index)
    @logger.info "Finished processing store chunk #{index + 1}."
  end

  def log_end_of_bulk_check(results)
    @logger.info "Finished bulk stock check. Found #{results.length} stock statuses."
  end

  def log_checking_stock(store_ids, product_ids)
    @logger.info "Checking stock for store IDs #{store_ids} and product IDs #{product_ids}..."
  end

  def send_stock_request(store_ids, product_ids)
    headers = build_headers
    body = build_body(store_ids, product_ids)

    @logger.debug "HTTParty Request: POST #{BASE_URL}, Headers: #{headers.inspect}, Body: #{body}"

    self.class.post(BASE_URL, headers:, body:)
  end

  def build_headers
    { 'Content-Type' => 'application/json' }
  end

  def build_body(store_ids, product_ids)
    {
      storeIdList: store_ids,
      productIdList: product_ids
    }.to_json
  end

  def handle_invalid_response!(response)
    raise StockFetcherError, "API responded with a #{response.code} status." if response.code >= 400
  end

  def parse_response(response)
    JSON.parse(response.body)
  end

  def validate_parsed_response!(parsed_response)
    return unless !parsed_response.key?('stockLevels') || parsed_response['stockLevels'].blank?

    raise StockFetcherError, "Unexpected response from API: #{parsed_response}"
  end

  def log_successful_retrieval(store_ids, product_ids)
    @logger.info "Stock retrieved successfully for store IDs #{store_ids} and product IDs #{product_ids}."
  end
end
