namespace :eto do

  namespace :import do

    desc "Create Client ID Map via API"
    task id_map: [:environment, "log:info_to_stdout"] do
      EtoApi::Tasks::UpdateClientLookupViaSftp.new.run!
    end

    desc "Import Client Demographics via API"
    task demographics: [:environment, "log:info_to_stdout"] do
      GrdaWarehouse::HMIS::Assessment.update_touch_points
      EtoApi::Tasks::UpdateClientDemographics.new.run!
    end

    desc "Import Client Demographics via API"
    task update_ids_and_demographics: [:environment, "log:info_to_stdout"] do
      EtoApi::Tasks::UpdateClientLookupViaSftp.new.run!
      GrdaWarehouse::HMIS::Assessment.update_touch_points
      # fetch health clients first since they tend to get seen more often.
      if GrdaWarehouse::Config.get(:healthcare_available)
        dest_client_ids = Health::Patient.pluck(:client_id)
        source_client_ids = GrdaWarehouse::WarehouseClient.where(destination_id: dest_client_ids).pluck(:source_id)
        EtoApi::Tasks::UpdateClientDemographics.new(client_ids: source_client_ids).run!
      end
      EtoApi::Tasks::UpdateClientDemographics.new.run!
    end

  end
end