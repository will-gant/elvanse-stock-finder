require 'rails_helper'
require 'webmock/rspec'

RSpec.describe BootsApiClient do
  describe '#check_stock' do
    let(:client) { described_class.new }
    let(:number_of_stores) { 10 }
    let(:number_of_products) { 1 }
    let(:store_ids) { FactoryBot.create_list(:random_id, number_of_stores) }
    let(:product_ids) { FactoryBot.create_list(:random_id, number_of_products) }
    let(:mocked_response) { mock_boots_api_response_body(store_ids: store_ids, product_ids: product_ids) }
    let(:response) { { status: 200, body: mocked_response, headers: {} } }

    before do
      stub_request(:post, "https://www.boots.com/online/psc/itemStock")
        .with(
          headers: {
            'Content-Type' => 'application/json'
          },
          body: {
            storeIdList: store_ids,
            productIdList: product_ids
          }
        )
        .to_return(response)
    end

    context 'with 10 store IDs' do
      context 'with 1 product ID' do
  
        it 'returns the parsed response body' do
          expect(client.check_stock(store_ids, product_ids)).to eq(JSON.parse(mocked_response))
        end

        context 'when the API returns an error' do
          let(:response) { { status: 503, body: nil, headers: {} } }
    
          it 'raises an ApiError' do
            expect { client.check_stock(store_ids, product_ids) }.to raise_error(BootsApiClient::ApiError, "API responded with a #{response[:status]} status.")
          end
        end
      end

      context 'with more than one product ID' do
        let(:number_of_products) { 2 }
  
        it 'raises an ArgumentError' do
          expect { client.check_stock(store_ids, product_ids) }.to raise_error(ArgumentError, "Need exactly 1 product_id, received #{number_of_products}")
        end
      end

      context 'with zero product IDs' do
        let(:number_of_products) { 0 }
  
        it 'raises an ArgumentError' do
          expect { client.check_stock(store_ids, product_ids) }.to raise_error(ArgumentError, "Need exactly 1 product_id, received #{number_of_products}")
        end
      end
    end

    context 'with more than 10 store IDs' do
      let(:number_of_stores) { 11 }

      it 'raises an ArgumentError' do
        expect { client.check_stock(store_ids, product_ids) }.to raise_error(ArgumentError, "Need exactly 10 store_ids, received #{number_of_stores}")
      end
    end

    context 'with fewer than 10 store IDs' do
      let(:number_of_stores) { 9 }

      it 'raises an ArgumentError' do
        expect { client.check_stock(store_ids, product_ids) }.to raise_error(ArgumentError, "Need exactly 10 store_ids, received #{number_of_stores}")
      end    end
  end
end
