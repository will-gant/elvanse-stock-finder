require 'rails_helper'
require 'webmock/rspec'

RSpec.describe StockFetcher, type: :service do
  permitted_stores_per_request = StockFetcher::PERMITTED_STORE_IDS_PER_REQUEST
  permitted_products_per_request = StockFetcher::PERMITTED_PRODUCT_IDS_PER_REQUEST

  let(:stock_fetcher) { described_class.new }

  let(:store_ids) { fake_store_ids(number_of_stores) }
  let(:product_ids) { fake_product_ids(number_of_products) }
  let(:number_of_stores) { permitted_stores_per_request }
  let(:number_of_products) { permitted_products_per_request }

  let(:statuses) { build_list(:stock_status, 2) }

  describe '#fetch' do
    before do
      allow(stock_fetcher).to receive(:bulk_check_stock).and_return(statuses)
    end

    it 'calls bulk_check_stock with correct product_ids and store_ids' do
      stock_fetcher.fetch(product_ids, store_ids)
      expect(stock_fetcher).to have_received(:bulk_check_stock).with(store_ids:, product_ids:)
    end
  end

  describe '#fetch_all' do
    let!(:products) { create_list(:product, 3) }
    let!(:stores) { create_list(:store, 2) }

    before do
      allow(stock_fetcher).to receive(:fetch).and_return(nil)
    end

    it 'retrieves all product IDs and store IDs from the database' do
      expect(Product).to receive(:pluck).with(:product_id).and_call_original
      expect(Store).to receive(:pluck).with(:store_id).and_call_original

      stock_fetcher.fetch_all
    end

    it 'calls #fetch with all product IDs and store IDs' do
      stock_fetcher.fetch_all
      expected_product_ids = products.map(&:product_id).map(&:to_s)
      expected_store_ids = stores.map(&:store_id).map(&:to_s)
      expect(stock_fetcher).to have_received(:fetch).with(array_including(expected_product_ids),
                                                          array_including(stores.map(&:store_id).map(&:to_s)))
    end
  end

  describe '#check_stock' do
    let(:stores) { create_list(:store, number_of_stores) }
    let(:products) { create_list(:product, number_of_products) }
    let(:store_ids) { stores.map(&:store_id).map(&:to_s) }
    let(:product_ids) { products.map(&:product_id).map(&:to_s) }
    let(:mocked_response) { mock_boots_api_response_body(store_ids:, product_ids:) }
    let(:response) { { status: 200, body: mocked_response, headers: {} } }
    let(:parsed_stock_levels) { JSON.parse(mocked_response)['stockLevels'] }

    before do
      stub_request(:post, StockFetcher::BASE_URL)
        .with(headers: { 'Content-Type' => 'application/json' }) do |request|
          body = JSON.parse(request.body)
          body['storeIdList'].sort == store_ids.sort && body['productIdList'].sort == product_ids.sort
        end
        .to_return(response)
    end

    it 'returns an array of StockStatus instances' do
      expect(stock_fetcher.check_stock(store_ids:,
                                       product_ids:)).to all(be_an_instance_of(StockStatus))
    end

    context "with #{permitted_stores_per_request} store IDs" do
      context "with #{permitted_products_per_request} product ID" do
        it 'returns an array of StockStatus objects' do
          result = stock_fetcher.check_stock(store_ids:, product_ids:)

          expect(result).to all(be_an_instance_of(StockStatus))

          parsed_stock_levels.each_with_index do |entry, index|
            expect(result[index].store.store_id).to eq(entry['storeId'].to_i)
            expect(result[index].product.product_id).to eq(entry['productId'].to_i)
            expect(result[index].status).to eq(entry['stockLevel'])
          end
        end

        context 'when the API returns an error' do
          let(:response) { { status: 503, body: nil, headers: {} } }

          it 'raises an ApiError' do
            expect do
              stock_fetcher.check_stock(store_ids:, product_ids:)
            end.to raise_error(StockFetcher::StockFetcherError, "API responded with a #{response[:status]} status.")
          end
        end
      end

      context 'with more than the permitted number of product ID' do
        let(:number_of_products) { permitted_products_per_request + 1 }

        it 'raises an ArgumentError' do
          expect do
            stock_fetcher.check_stock(store_ids:, product_ids:)
          end.to raise_error(ArgumentError, "Need exactly 1 product_id, received #{number_of_products}")
        end
      end

      context 'with zero product IDs' do
        let(:number_of_products) { 0 }

        it 'raises an ArgumentError' do
          expect do
            stock_fetcher.check_stock(store_ids:, product_ids:)
          end.to raise_error(ArgumentError, "Need exactly 1 product_id, received #{number_of_products}")
        end
      end
    end

    context "with more than #{permitted_stores_per_request} store IDs" do
      let(:number_of_stores) { permitted_stores_per_request + 1 }

      it 'raises an ArgumentError' do
        expect do
          stock_fetcher.check_stock(store_ids:, product_ids:)
        end.to raise_error(ArgumentError, "Need exactly 10 store_ids, received #{number_of_stores}")
      end
    end

    context "with fewer than #{permitted_stores_per_request} store IDs" do
      let(:number_of_stores) { permitted_stores_per_request - 1 }

      it 'raises an ArgumentError' do
        expect do
          stock_fetcher.check_stock(store_ids:, product_ids:)
        end.to raise_error(ArgumentError, "Need exactly 10 store_ids, received #{number_of_stores}")
      end
    end
  end

  describe '#bulk_check_stock' do
    let(:stores) { create_list(:store, number_of_stores) }
    let(:products) { create_list(:product, number_of_products) }
    let(:store_ids) { stores.map(&:store_id).map(&:to_s) }
    let(:product_ids) { products.map(&:product_id).map(&:to_s) }

    before do
      allow(stock_fetcher).to receive(:check_stock) do |store_ids:, product_ids:|
        store_ids.flat_map do |store_id|
          product_ids.map do |product_id|
            build(:stock_status, store: Store.find_by(store_id:), product: Product.find_by(product_id:))
          end
        end
      end

      @delay_count = 0
      allow(stock_fetcher).to receive(:delay_next_request) { @delay_count += 1 }
    end

    it 'returns an array of StockStatus instances' do
      expect(stock_fetcher.bulk_check_stock(store_ids:, product_ids:)).to all(be_an_instance_of(StockStatus))
    end

    context "when the number of stores is divisible by #{permitted_stores_per_request}" do
      it 'returns as a stock status for each product at each store' do
        expect(stock_fetcher.bulk_check_stock(store_ids:,
                                              product_ids:).count).to eq(store_ids.count * product_ids.count)
      end
    end

    context "when the number of products is divisible by #{permitted_products_per_request}" do
      it 'returns as a stock status for each product at each store' do
        expect(stock_fetcher.bulk_check_stock(store_ids:,
                                              product_ids:).count).to eq(store_ids.count * product_ids.count)
      end
    end

    context "when the number of stores is not divisible by #{permitted_stores_per_request}" do
      let(:number_of_stores) { permitted_stores_per_request + 1 }

      it 'returns as a stock status for each product at each store' do
        expect(stock_fetcher.bulk_check_stock(store_ids:,
                                              product_ids:).count).to eq(store_ids.count * product_ids.count)
      end

      it 'returns only unique stock statuses' do
        expect(stock_fetcher.bulk_check_stock(store_ids:,
                                              product_ids:).uniq.count).to eq(store_ids.count * product_ids.count)
      end
    end

    context "when the number of products is not divisible by #{permitted_products_per_request}" do
      let(:number_of_products) { permitted_products_per_request + 1 }

      it 'returns as a stock status for each product at each store' do
        expect(stock_fetcher.bulk_check_stock(store_ids:,
                                              product_ids:).count).to eq(store_ids.count * product_ids.count)
      end

      it 'returns only unique stock statuses' do
        expect(stock_fetcher.bulk_check_stock(store_ids:,
                                              product_ids:).uniq.count).to eq(store_ids.count * product_ids.count)
      end
    end

    context "when the number of store IDs is not at least #{permitted_stores_per_request}" do
      let(:number_of_stores) { permitted_stores_per_request - 1 }

      it 'raises an ArgumentError' do
        expect { stock_fetcher.bulk_check_stock(store_ids:, product_ids:) }.to raise_error(
          ArgumentError, "Need at least #{permitted_stores_per_request} store_ids, received #{number_of_stores}"
        )
      end
    end

    context "when the number of product IDs is not at least #{permitted_products_per_request}" do
      let(:number_of_products) { permitted_products_per_request - 1 }

      it 'raises an ArgumentError' do
        expect { stock_fetcher.bulk_check_stock(store_ids:, product_ids:) }.to raise_error(
          ArgumentError, "Need at least #{permitted_products_per_request} product_id, received #{number_of_products}"
        )
      end
    end

    context 'rate limiting' do
      context 'with twice as many store IDs as permitted for a single request' do
        let(:number_of_stores) { permitted_stores_per_request * 2 }

        it 'delays twice' do
          stock_fetcher.bulk_check_stock(store_ids:, product_ids:)

          expect(@delay_count).to eq(2)
        end
      end

      context 'with twice as many product IDs as permitted for a single request' do
        let(:number_of_products) { permitted_products_per_request * 2 }

        it 'delays twice' do
          stock_fetcher.bulk_check_stock(store_ids:, product_ids:)

          expect(@delay_count).to eq(2)
        end
      end
    end
  end

  describe '#products_for_dose' do
    let(:medicine) { Medicine.create(name: 'Test Medicine') }
    let!(:product1) { Product.create(medicine: medicine, dose: '10mg') }
    let!(:product2) { Product.create(medicine: medicine, dose: '20mg') }
    let!(:product3) { Product.create(medicine: Medicine.create(name: 'Another Medicine'), dose: '10mg') }

    subject(:stock_fetcher) { described_class.new }

    context 'when there are products with the given medicine and dose' do
      it 'returns the products with the specified medicine and dose' do
        result = stock_fetcher.products_for_dose(medicine, '10mg')
        expect(result).to contain_exactly(product1)
      end
    end

    context 'when there are no products with the given medicine and dose' do
      it 'returns an empty array' do
        result = stock_fetcher.products_for_dose(medicine, '30mg')
        expect(result).to be_empty
      end
    end

    context 'when there are products with the same dose but different medicine' do
      it 'does not return the products with a different medicine' do
        result = stock_fetcher.products_for_dose(medicine, '10mg')
        expect(result).not_to include(product3)
      end
    end
  end
end
