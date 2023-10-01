namespace :ac_hmis do
  # rails driver:hmis_external_apis:ac_hmis:update_unit_availability
  # or to force an update
  # rails driver:hmis_external_apis:ac_hmis:update_unit_availability[force]
  task :update_unit_availability, [:force] => :environment do |_task, args|
    next unless HmisEnforcement.hmis_enabled? && HmisExternalApis::AcHmis::Mper.enabled?

    force = args.force == 'force'
    HmisExternalApis::AcHmis::UpdateUnitAvailabilityJob.perform_now(force: force)
  end
end
