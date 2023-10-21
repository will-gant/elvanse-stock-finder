require 'yaml'

namespace :import do
  desc 'Import data from YAML file to the database'
  task :data => :environment do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    file_path = 'data.yaml'
    data = YAML.load_file(file_path)

    data['medicines'].each do |medicine_name, doses|
      doses.each do |dose|
        medicine = Medicine.find_or_create_by!(name: medicine_name)

        producer = Producer.find_or_create_by!(name: dose['producer'])

        product = Product.find_or_create_by!(
          medicine: medicine,
          producer: producer
        )

        dose = product.doses.find_or_create_by!(
          product: product,
          value: dose['dose_value'],
          unit: dose['dose_unit'],
          concept_id: dose['conceptId'],
          category: dose['type']
        )
      end
    end

    data['locations']['regions'].each do |region_id, region_data|
      region = Region.find_or_create_by!(region_id: region_id, name: region_data['name'])

      region_data['areas'].each do |area_id, area_data|
        area = region.areas.find_or_create_by!(area_id: area_id, name: area_data['name'])

        area_data['stores'].each do |store_id, store_data|
          if store_data['manager'].present?
            manager_data = store_data['manager']
            manager = Manager.find_or_create_by!(email: manager_data['email']) do |m|
              m.name = manager_data['name']
            end
          end

          store = area.stores.find_or_create_by!(
            displayname: store_data['displayname'],
            isMidnightPharmacy: store_data['isMidnightPharmacy'],
            isPharmacy: store_data['isPharmacy'],
            isPrescriptionStoreCollectionAvailable: store_data['isPrescriptionStoreCollectionAvailable'],
            name: store_data['name'],
            ndsasqm: store_data['ndsasqm'],
            nhsMarket: store_data['nhsMarket'],
            openDate: store_data['openDate'],
            primaryCareOrganisation: store_data['primaryCareOrganisation'],
            store_id: store_id,
            manager: manager
          )

          address_data = store_data.dig(:Address)&.presence
          
          if address_data.present?
            if store.address.blank?
              address = store.create_address!(
                administrativeArea: address_data['administrativeArea'],
                countryCode: address_data['countryCode'],
                county: address_data['county'],
                locality: address_data['locality'],
                postcode: address_data['postcode'],
                street: address_data['street'],
                town: address_data['town']
              )
            end

            grid_location_data = address_data.dig(:gridLocation)&.presence

            if grid_location_data.present? && address.grid_location.blank?
              grid_location_data = address_data['gridLocation']
              address.create_grid_location!(
                latitude: grid_location_data['latitude'],
                longitude: grid_location_data['longitude'],
                propertyEasting: grid_location_data['propertyEasting'],
                propertyNorthing: grid_location_data['propertyNorthing']
              )
            end
          end

          status_data = store_data.dig(:status)&.presence

          if status_data.present? && store.status.blank?
            status_data = store_data['status']
            store.create_status!(
              code: status_data['code'].to_i,
              text: status_data['text']
            )
          end

          contact_details_data = store_data.dig(:contactDetails)&.presence

          if contact_details_data.present? && store.contact_details.empty?
            contact_details_data = store_data['contactDetails']
            contact_details_data&.each do |contact_data|
              store.contact_details.create!(phone: contact_data['phone'])
            end
          end

          van_routes_data = store_data.dig(:vanRoutes)&.presence

          if van_routes_data.present? && store.van_routes.empty?
            van_routes_data = store_data['vanRoutes']
            van_routes_data&.each do |van_route_data|
              store.van_routes.create!(code: van_route_data['code'].to_i)
            end
          end
        end
      end
    end

    puts 'Data imported successfully!'
  end
end
