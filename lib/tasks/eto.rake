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
      # GrdaWarehouse::HMIS::Assessment.update_touch_points
      EtoApi::Tasks::UpdateClientDemographics.new.run!
    end

  end
end