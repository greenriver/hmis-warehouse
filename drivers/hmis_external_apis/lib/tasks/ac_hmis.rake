namespace :ac_hmis do
  task :update_unit_availability, [] => [:environment] do
    HmisExternalApis::AcHmis::UpdateUnitAvailabilityJob.perform_now
  end
end
