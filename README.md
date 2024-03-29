# Elvanse stock finder

Backend-only Rails app to find pharmacies in the UK and Ireland that have current stocks of the ADHD medication [lisdexamfetamine](https://bnf.nice.org.uk/drugs/lisdexamfetamine-mesilate/) (branded 'Elvanse'). Polls the Boots [prescription stock checker](https://www.boots.com/online/psc/) API at a rate of 5 requests per minute to populate a database with current stock levels, which can then be queried however you wish. Note:
* lisdexamfetamine is sold in the UK under multiple brand names ('Elvanse', 'Elvanse Adult', etc)
* This application refers to each dose of a given brand as a 'product' (i.e. 20mg Elvanse is a product, 20mg Elvanse Adult is a different product).
* There are 15 known 'products', covering doses from 20mg to 70mg inclusive
* Boots organises its pharmacies in 13 'regions', which are subdivided into 108 'areas', with a total of 1,110 pharmacies between them.
* Each request to the API must check the availability of exactly one product at 10 pharmacies (any deviation in either number produces a non-2xx response).
* Requests appear to be subject to a rate limit of five requests per minute per IP address
* Therefore it takes 111 requests to check the availability of a single product at all pharmacies, and 1,665 requests to check all products at all pharmacies. At the maximum permitted request rate, that's just over 5 hours 30 minutes.

To interpret `StockStatus.status`:

| **StockStatus.status** | **Meaning**              |
|------------------------|--------------------------|
| G                      | 🟢 Green - in stock      |
| A                      | 🟡 Amber - limited stock |
| R                      | 🔴 Red - out of stock    |

## Instructions

1. Install dependencies:
    ```console
    bundle install
    ```
1. Import the contents of `data.yaml` into the database:
    ```console
    bundle exec rake db:create
    bundle exec rake db:migrate
    bundle exec rake import:data
    ```
1. Get the latest stock levels from Boots by running the following in the Rails console:
    ```ruby
    fetcher = StockFetcher.new

    # check all
    fetcher.fetch_all

    # check specific doses and/or regions
    medicine = Medicine.find_by(name: 'lisdexamfetamine') # currently this is the only medicine

    products = fetcher.products_for_dose(medicine, ['30mg', '50mg']) # dose options are 20mg, 30mg, 40mg, 50mg, 60mg and 70mg

    fetcher.fetch_custom(products, 'South East', 'London') # region options are "Central England", "East of England", "Ireland", "London", "Northern England and NI", "Scotland", "South East", "Specialist Pharmacy", "Travel", "Unassigned", "Wales", "Wales Merseyside West Midlands", "West of Scotland"
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
