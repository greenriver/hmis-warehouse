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

    desc 'Update client consent from HMIS Clients'
    task maintain_client_consent: [:environment, "log:info_to_stdout"] do
      GrdaWarehouse::HmisClient.maintain_client_consent
    end

    desc "Add eto_last_updated to any hmis_clients and hmis_forms where missing"
    task maintain_eto_last_updated: [:environment, "log:info_to_stdout"] do
      GrdaWarehouse::HmisClient.where(eto_last_updated: nil).
        where.not(response: nil).
        find_each do |client|
          client.update(eto_last_updated: EtoApi::Base.parse_date(JSON.parse(client.response)['AuditDate']))
        end

      GrdaWarehouse::HmisForm.where(eto_last_updated: nil).
        where.not(api_response: nil).
        find_each do |form|
          form.update(eto_last_updated: EtoApi::Base.parse_date(form.api_response['AuditDate']))
        end
    end

    desc "Fetch ETO data via QaaWS and API"
    task demographics_and_touch_points: [:environment, "log:info_to_stdout"] do
      # Ensure we know about all the available touch points
      GrdaWarehouse::HMIS::Assessment.update_touch_points
      # somewhat hackish, but figure out which sites we have access to
      ENV.select{|k,v| k.include?('ETO_API_SITE') && v.presence != 'unknown' }.each do |k,v|
        identifier = k.sub('ETO_API_SITE', '')
        Bo::ClientIdLookup.new(api_site_identifier: identifier, start_time: 1.years.ago).update_all!
      end
      EtoApi::Tasks::UpdateEtoData.new.run!
    end
  end
end