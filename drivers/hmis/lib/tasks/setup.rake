desc 'Seed form definitions'
task seed_definitions: [:environment, 'log:info_to_stdout'] do
  ::HmisUtil::JsonForms.new.tap do |builder|
    # Load ALL the latest record definitions from JSON files.
    # This also ensures that any system-level instances exist.
    builder.seed_record_form_definitions
    # Load ALL the latest assessment definition froms JSON files.
    builder.seed_assessment_form_definitions
    # In development, create the initial instances for occurrence-point collection.
    builder.create_default_occurrence_point_instances! if Rails.env.development?
  end
end

desc 'Seed service types'
task seed_service_types: [:environment, 'log:info_to_stdout'] do
  data_source_id = GrdaWarehouse::DataSource.hmis.first&.id
  next unless data_source_id.present?

  # Create 1 CustomServiceCategory per HUD RecordType, and
  # 1 CustomServiceType per HUD TypeProvided
  ::HmisUtil::ServiceTypes.seed_hud_service_types(data_source_id)
  # Create FormInstances specifying which Services are available per Project Type / Funder
  # NOTE: This should be run once on setup, but we don't want to re-run on each deploy
  # because each installation may need a different setup.
  ::HmisUtil::ServiceTypes.seed_hud_service_form_instances
end

desc 'Kick off job to create CustomAssessments by grouping related records'
task migrate_assessments: [:environment, 'log:info_to_stdout'] do
  GrdaWarehouse::DataSource.hmis.pluck(:id).each do |id|
    Hmis::MigrateAssessmentsJob.perform_later(data_source_id: id)
  end
end
