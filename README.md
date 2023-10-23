# README

## Instructions

1. Install dependencies:
    ```console
    bundle install
    ```
1. Import the contents of `data.yaml` into the database:
    ```console
    bundle exec rake db:create
    bundle exec rake import:data
    ```
1. Get the latest stock levels from Boots by running the following in the Rails console:
    ```ruby
    fetcher = StockFetcher.new

    medicine = Medicine.find_by(name: 'lisdexamfetamine')

    products = fetcher.products_for_dose(medicine, ['30mg', '50mg'])

    fetcher.fetch_custom(products, 'South East', 'London')
    ```
1. Check stock levels. For example:
    ```ruby
    stores_with_50mg = Store.joins(area: :region).joins(stock_statuses: :product).where(stock_statuses: {
      status: ['A', 'G'],
      checked_at: 4.hours.ago...
    }, products: {
      dose: '50mg'
    }, regions: {
      name: ['South East', 'London']
    })

    stores_with_30mg = Store.joins(area: :region).joins(stock_statuses: :product).where(stock_statuses: {
      status: ['A', 'G'],
      checked_at: 4.hours.ago...
    }, products: {
      dose: '30mg'
    }, regions: {
      name: ['South East', 'London']
    })

    stores_with_both_doses = Store.where(id: stores_with_50mg).where(id: stores_with_30mg).distinct
    =>
    [#<Store:0x00000001124837e0
      id: 30,
      displayname: "Bromley The Glades Shopping Centre",
      isMidnightPharmacy: true,
      isPharmacy: true,
      isPrescriptionStoreCollectionAvailable: true,
      name: "Bromley The Glades Sc",
      ndsasqm: 2088,
      nhsMarket: "England",
      openDate: Mon, 28 Oct 1991,
      primaryCareOrganisation: "5A7",
      store_id: 836,
      area_id: 4,
      manager_id: 12,
      created_at: Sun, 22 Oct 2023 12:45:43.077080000 UTC +00:00,
      updated_at: Sun, 22 Oct 2023 12:45:43.077080000 UTC +00:00>,
    #<Store:0x0000000112cac778
      id: 51,
      displayname: "Banstead 85-87 High Street",
      isMidnightPharmacy: true,
      isPharmacy: true,
      isPrescriptionStoreCollectionAvailable: true,
      name: "Banstead 85-87 High St",
      ndsasqm: 209,
      nhsMarket: "England",
      openDate: Thu, 27 Mar 1986,
      primaryCareOrganisation: "5P5",
      store_id: 1414,
      area_id: 6,
      manager_id: 33,
      created_at: Sun, 22 Oct 2023 12:45:43.316828000 UTC +00:00,
      updated_at: Sun, 22 Oct 2023 12:45:43.316828000 UTC +00:00>,
      ...
    ```