require 'rails_helper'
require 'webmock/rspec'

RSpec.describe BootsApiClient do
  permitted_stores_per_request = BootsApiClient::PERMITTED_STORE_IDS_PER_REQUEST
  permitted_products_per_request = BootsApiClient::PERMITTED_PRODUCT_IDS_PER_REQUEST

  let(:client) { described_class.new }
  let(:number_of_stores) { permitted_stores_per_request }
  let(:number_of_products) { permitted_products_per_request }
  let(:store_ids) { fake_store_ids(number_of_stores) }
  let(:product_ids) { fake_product_ids(number_of_products) }
  let(:permitted_stores_per_request) { BootsApiClient::PERMITTED_STORE_IDS_PER_REQUEST }
  let(:permitted_products_per_request) { BootsApiClient::PERMITTED_PRODUCT_IDS_PER_REQUEST }

  describe '#check_stock' do
    let(:mocked_response) { mock_boots_api_response_body(store_ids:, product_ids:) }
    let(:response) { { status: 200, body: mocked_response, headers: {} } }
    let(:parsed_stock_levels) { JSON.parse(mocked_response)['stockLevels'] }

    before do
      stub_request(:post, 'https://www.boots.com/online/psc/itemStock')
        .with(headers: { 'Content-Type' => 'application/json' }) do |request|
          body = JSON.parse(request.body)
          body['storeIdList'].sort == store_ids.sort && body['productIdList'].sort == product_ids.sort
        end
        .to_return(response)
    end

    it 'returns an array of StockStatus instances' do
      expect(client.check_stock(store_ids:, product_ids:)).to all(be_an_instance_of(StockStatus))
    end

    context "with #{permitted_stores_per_request} store IDs" do
      context "with #{permitted_products_per_request} product ID" do
        it 'returns an array of StockStatus objects' do
          result = client.check_stock(store_ids:, product_ids:)

          expect(result).to all(be_an_instance_of(StockStatus))

          parsed_stock_levels.each_with_index do |entry, index|
            expect(result[index].store_id).to eq(entry['storeId'].to_i)
            expect(result[index].product_id).to eq(entry['productId'].to_i)
            expect(result[index].status).to eq(entry['stockLevel'])
          end
        end

        context 'when the API returns an error' do
          let(:response) { { status: 503, body: nil, headers: {} } }

          it 'raises an ApiError' do
            expect do
              client.check_stock(store_ids:,
                                 product_ids:)
            end.to raise_error(BootsApiClient::ApiError, "API responded with a #{response[:status]} status.")
          end
        end
      end

      context 'with more than the permitted number of product ID' do
        let(:number_of_products) { permitted_products_per_request + 1 }

        it 'raises an ArgumentError' do
          expect do
            client.check_stock(store_ids:,
                               product_ids:)
          end.to raise_error(ArgumentError, "Need exactly 1 product_id, received #{number_of_products}")
        end
      end

      context 'with zero product IDs' do
        let(:number_of_products) { 0 }

        it 'raises an ArgumentError' do
          expect do
            client.check_stock(store_ids:,
                               product_ids:)
          end.to raise_error(ArgumentError, "Need exactly 1 product_id, received #{number_of_products}")
        end
      end
    end

    context "with more than #{permitted_stores_per_request} store IDs" do
      let(:number_of_stores) { permitted_stores_per_request + 1 }

      it 'raises an ArgumentError' do
        expect do
          client.check_stock(store_ids:,
                             product_ids:)
        end.to raise_error(ArgumentError, "Need exactly 10 store_ids, received #{number_of_stores}")
      end
    end

    context "with fewer than #{permitted_stores_per_request} store IDs" do
      let(:number_of_stores) { permitted_stores_per_request - 1 }

      it 'raises an ArgumentError' do
        expect do
          client.check_stock(store_ids:,
                             product_ids:)
        end.to raise_error(ArgumentError, "Need exactly 10 store_ids, received #{number_of_stores}")
      end
    end
  end

  describe '#bulk_check_stock' do
    before do
      allow(client).to receive(:check_stock) do |store_chunk, product_chunk|
        store_chunk.flat_map do |store_id|
          product_chunk.map do |product_id|
            build_stubbed(:stock_status, store_id:, product_id:)
          end
        end
      end

      @delay_count = 0
      allow(client).to receive(:delay_next_request) { @delay_count += 1 }
    end

    it 'returns an array of StockStatus instances' do
      expect(client.bulk_check_stock(store_ids:, product_ids:)).to all(be_an_instance_of(StockStatus))
    end

    context "when the number of stores is divisible by #{permitted_stores_per_request}" do
      it 'returns as a stock status for each product at each store' do
        expect(client.bulk_check_stock(store_ids:, product_ids:).count).to eq(store_ids.count * product_ids.count)
      end
    end

    context "when the number of products is divisible by #{permitted_products_per_request}" do
      it 'returns as a stock status for each product at each store' do
        expect(client.bulk_check_stock(store_ids:, product_ids:).count).to eq(store_ids.count * product_ids.count)
      end
    end

    context "when the number of stores is not divisible by #{permitted_stores_per_request}" do
      let(:number_of_stores) { permitted_stores_per_request + 1 }

      it 'returns as a stock status for each product at each store' do
        expect(client.bulk_check_stock(store_ids:, product_ids:).count).to eq(store_ids.count * product_ids.count)
      end

      it 'returns only unique stock statuses' do
        expect(client.bulk_check_stock(store_ids:, product_ids:).uniq.count).to eq(store_ids.count * product_ids.count)
      end
    end

    context "when the number of products is not divisible by #{permitted_products_per_request}" do
      let(:number_of_products) { permitted_products_per_request + 1 }

      it 'returns as a stock status for each product at each store' do
        expect(client.bulk_check_stock(store_ids:, product_ids:).count).to eq(store_ids.count * product_ids.count)
      end

      it 'returns only unique stock statuses' do
        expect(client.bulk_check_stock(store_ids:, product_ids:).uniq.count).to eq(store_ids.count * product_ids.count)
      end
    end

    context "when the number of store IDs is not at least #{permitted_stores_per_request}" do
      let(:number_of_stores) { permitted_stores_per_request - 1 }

      it 'raises an ArgumentError' do
        expect { client.bulk_check_stock(store_ids:, product_ids:) }.to raise_error(
          ArgumentError, "Need at least #{permitted_stores_per_request} store_ids, received #{number_of_stores}"
        )
      end
    end

    context "when the number of product IDs is not at least #{permitted_products_per_request}" do
      let(:number_of_products) { permitted_products_per_request - 1 }

      it 'raises an ArgumentError' do
        expect { client.bulk_check_stock(store_ids:, product_ids:) }.to raise_error(
          ArgumentError, "Need at least #{permitted_products_per_request} product_id, received #{number_of_products}"
        )
      end
    end

    context 'rate limiting' do
      context 'with twice as many store IDs as permitted for a single request' do
        let(:number_of_stores) { permitted_stores_per_request * 2 }

        it 'delays twice' do
          client.bulk_check_stock(store_ids:, product_ids:)

          expect(@delay_count).to eq(2)
        end
      end

      context 'with twice as many product IDs as permitted for a single request' do
        let(:number_of_products) { permitted_products_per_request * 2 }

        it 'delays twice' do
          client.bulk_check_stock(store_ids:, product_ids:)

          expect(@delay_count).to eq(2)
        end
      end
    end
  end
end
