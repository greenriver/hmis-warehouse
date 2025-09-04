# frozen_string_literal: true

namespace :ac_hmis do
  # rails driver:hmis_external_apis:ac_hmis:update_unit_availability
  # or to force an update
  # rails driver:hmis_external_apis:ac_hmis:update_unit_availability[force]
  task :update_unit_availability, [:force] => :environment do |_task, args|
    next unless HmisEnforcement.hmis_enabled? && HmisExternalApis::AcHmis::Mper.enabled?

    force = args.force == 'force'
    HmisExternalApis::AcHmis::UpdateUnitAvailabilityJob.perform_now(force: force)
  end

  # rails driver:hmis_external_apis:ac_hmis:import_housing_assessments[wait_list.xlsx,<ce_project_id>]
  task :import_housing_assessments, [:filename, :project_id] => :environment do |_task, args|
    next unless HmisEnforcement.hmis_enabled?
    next unless Rails.env.development? || HmisExternalApis::AcHmis::Mci.enabled?

    HmisExternalApis::AcHmis::Importers::HousingAssessmentImporter.call(args.filename, ce_project_id: args.project_id, dry_run: false)
  end
end
