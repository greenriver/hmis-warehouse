namespace :eto do
  
  namespace :import do

    desc "Create Client ID Map via API"
    task id_map: [:environment, "log:info_to_stdout"] do 
      EtoApi::Tasks::UpdateClientLookup.new.run!
    end

    desc "Import Client Demographics via API"
    task demographics: [:environment, "log:info_to_stdout"] do 
      EtoApi::Tasks::UpdateClientDemographics.new.run!
    end
  end
end