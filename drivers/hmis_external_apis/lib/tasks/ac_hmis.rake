namespace :ac_hmis do
  task :update_unit_availability, [] => [:environment] do
    data_source = HmisExternalApis::AcHmis.data_source
    HmisExternalApis::AcHmis::UpdateUnitAvailabilityJob.perform_now(data_source_id: data_source.id)
  end
end
