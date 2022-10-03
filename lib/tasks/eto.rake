namespace :eto do

  namespace :import do
    desc 'Update client consent from HMIS Clients'
    task maintain_client_consent: [:environment, "log:info_to_stdout"] do
      GrdaWarehouse::HmisClient.maintain_client_consent
    end

    desc "Add eto_last_updated to any hmis_clients and hmis_forms where missing"
    task maintain_eto_last_updated: [:environment, "log:info_to_stdout"] do
      GrdaWarehouse::HmisClient.where(eto_last_updated: nil).
        where.not(response: nil).select(:id, :response).
        find_each(batch_size: 250) do |client|
          client.update(eto_last_updated: EtoApi::Base.parse_date(JSON.parse(client.response)['AuditDate']))
        end

      GrdaWarehouse::HmisForm.where(eto_last_updated: nil).
        where(assessment_id: GrdaWarehouse::HMIS::Assessment.where(fetch: true).select(:assessment_id)).
        where.not(api_response: nil).select(:id, :api_response).
        find_each(batch_size: 250) do |form|
          form.update(eto_last_updated: EtoApi::Base.parse_date(form.api_response['AuditDate']))
        end
    end

    # bin/rake eto:import:demographics_and_touch_points[start_date='2019-06-06']
    desc "Fetch ETO data via QaaWS and API"
    task :demographics_and_touch_points, [:start_date] => [:environment, "log:info_to_stdout"] do |t, args|
      # start_date = args.start_date&.to_date || 6.months.ago
      start_date = args.start_date&.to_date || 2.years.ago.to_date
      # Fetch via QaaWS all the available
      GrdaWarehouse::EtoApiConfig.active.find_each do |config|
        data_source_id = config.data_source_id
        Importing::EtoUpdateEverythingJob.perform_later(
          start_date: start_date.to_s,
          data_source_id: data_source_id,
        )
      end
      # Eccovia too!
      EccoviaData::Fetch.all.each(&:fetch_updated) if RailsDrivers.loaded.include?(:eccovia_data)
    end
  end
end
