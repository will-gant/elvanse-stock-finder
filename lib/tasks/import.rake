require 'yaml'

namespace :import do
  desc 'Import data from YAML file to the database'
  task data: :environment do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    file_path = 'data.yaml'
    data = YAML.load_file(file_path)

    data['medicines'].each do |medicine, doses|
      medicine = Medicine.find_or_create_by!(name: medicine)

      doses.each do |dose_value, dose_data|
        product_ids = dose_data['product_ids']
        product_ids.each do |product_id|
          product = Product.find_or_create_by!(
            medicine:,
            dose: dose_value,
            product_id:
          )
        end
      end
    end

    data['locations']['regions'].each do |region_id, region_data|
      region = Region.find_or_create_by!(region_id:, name: region_data['name'])

      region_data['areas'].each do |area_id, area_data|
        area = region.areas.find_or_create_by!(area_id:, name: area_data['name'])

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
            store_id:,
            manager:
          )

          address_data = store_data.dig('Address')&.presence

          if address_data.present?
            address = Address.find_or_create_by!(
              store:,
              administrativeArea: address_data['administrativeArea'],
              countryCode: address_data['countryCode'],
              county: address_data['county'],
              locality: address_data['locality'],
              postcode: address_data['postcode'],
              street: address_data['street'],
              town: address_data['town']
            )

            grid_location_data = address_data.dig('gridLocation')&.presence

            if grid_location_data.present? && address.grid_location.blank?
              grid_location_data = address_data['gridLocation']

              GridLocation.find_or_create_by!(
                address:,
                latitude: grid_location_data['latitude'],
                longitude: grid_location_data['longitude'],
                propertyEasting: grid_location_data['propertyEasting'],
                propertyNorthing: grid_location_data['propertyNorthing']
              )
            end
          end

          status_data = store_data.dig('status')&.presence

          if status_data.present? && store.status.blank?
            status_data = store_data['status']

            StoreStatus.find_or_create_by!(
              store:,
              code: status_data['code'].to_i,
              text: status_data['text']
            )
          end

          contact_details_data = store_data.dig('contactDetails')&.presence

          if contact_details_data.present? && store.contact_details.empty?
            contact_details_data = store_data['contactDetails']

            contact_details_data.each do |contact_detail, value|
              if contact_detail == 'phone' && value.present?
                ContactDetail.find_or_create_by!(
                  store:,
                  phone: value
                )
              end
            end
          end

          van_routes_data = store_data.dig('vanRoutes', 'code')&.presence

          if van_routes_data.present? && store.van_routes.empty?
            van_routes_data = store_data['vanRoutes']

            van_routes_data&.each do |van_route_data|
              VanRoute.find_or_create_by!(
                store:,
                code: van_route_data['code'].to_s,
              )
            end
          end
        end
      end
    end

    puts 'Data imported successfully!'
  end
end
