namespace :import do
  desc "Import stores from YAML file"
  task stores: :environment do
    require 'yaml'

    filepath = '/Users/will/Workspace/boots/stores.yaml'
    data = YAML.load_file(filepath)

    data["regions"].each do |region_id, region_data|
      region = Region.create!(id: region_id, name: region_data["name"])

      region_data["areas"].each do |area_id, area_data|
        area = Area.create!(id: area_id, name: area_data["name"], region: region)

        area_data["stores"].each do |store_id, store_data|
          address_data = store_data["Address"]
          address = Address.create!(store_data["Address"].except("gridLocation"))

          if address_data["gridLocation"]
            GridLocation.create!(address_data["gridLocation"].merge(address: address))
          end

          if store_data["manager"]
            manager = Manager.create!(store_data["manager"])
          end

          if store_data["status"]
            status = Status.create!(store_data["status"])
          end

          store = Store.create!(
            id: store_id,
            displayname: store_data["displayname"],
            isMidnightPharmacy: store_data["isMidnightPharmacy"],
            isPharmacy: store_data["isPharmacy"],
            isPrescriptionStoreCollectionAvailable: store_data["isPrescriptionStoreCollectionAvailable"],
            name: store_data["name"],
            ndsasqm: store_data["ndsasqm"],
            nhsMarket: store_data["nhsMarket"],
            openDate: store_data["openDate"],
            primaryCareOrganisation: store_data["primaryCareOrganisation"],
            deliveryChain: store_data["deliveryChain"],
            manager: manager,
            address: address,
            status: status,
            area: area
          )

          if store_data["contactDetails"]
            ContactDetail.create!(store_data["contactDetails"].merge(store: store))
          end

          if store_data["vanRoutes"]
            store_data["vanRoutes"].each do |van_route_data|
              VanRoute.create!(van_route_data.merge(store: store))
            end
          end
        end
      end
    end
  end
end
