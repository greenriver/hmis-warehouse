namespace :ac_hmis do
  task :update_unit_availability, [:force] => :environment do |_task, args|
    return unless HmisEnforcement.hmis_enabled? && HmisExternalApis::AcHmis::Mper.enabled?

    data_source = HmisExternalApis::AcHmis.data_source
    force = args.force == 'force'
    HmisExternalApis::AcHmis::UpdateUnitAvailabilityJob.perform_now(
      data_source_id: data_source.id,
      force: force,
    )
  end
end
