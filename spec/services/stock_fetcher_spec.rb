require 'rails_helper'

RSpec.describe StockFetcher, type: :service do
  let(:stock_fetcher) { described_class.new }
  let(:product_ids) { [1, 2, 3] }
  let(:store_ids) { [100, 200] }
  let(:statuses) { build_list(:stock_status, 2) }

  describe '#fetch' do
    let(:mock_client) { instance_double(BootsApiClient, bulk_check_stock: statuses) }

    before do
      allow(BootsApiClient).to receive(:new).and_return(mock_client)
    end

    context 'when the API returns valid stock statuses' do
      it 'persists each stock status' do
        stock_fetcher.fetch(product_ids, store_ids)
        expect(StockStatus.count).to eq(2)
      end
    end

    context 'when the API returns no stock statuses' do
      before do
        allow(mock_client).to receive(:bulk_check_stock).and_return([])
      end

      it 'does not attempt to persist any stock status' do
        stock_fetcher.fetch(product_ids, store_ids)
        expect(StockStatus.count).to eq(0)
      end
    end
  end

  describe '#fetch_all' do
    let!(:products) { create_list(:product, 3) }
    let!(:stores) { create_list(:store, 2) }

    before do
      allow(stock_fetcher).to receive(:fetch)
    end

    it 'retrieves all product IDs and store IDs from the database' do
      expect(Product).to receive(:pluck).with(:product_id).and_call_original
      expect(Store).to receive(:pluck).with(:store_id).and_call_original

      stock_fetcher.fetch_all
    end

    it 'calls #fetch with all product IDs and store IDs' do
      expect(stock_fetcher).to receive(:fetch).with(products.map { |p| p.product_id.to_s }, stores.map do |s|
                                                                                              s.store_id.to_s
                                                                                            end)

      stock_fetcher.fetch_all
    end
  end
end
