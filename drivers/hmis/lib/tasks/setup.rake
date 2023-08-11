desc 'Seed form definitions'
task seed_definitions: [:environment, 'log:info_to_stdout'] do
  ::HmisUtil::JsonForms.new.tap do |builder|
    builder.seed_record_form_definitions
    builder.seed_assessment_form_definitions
  end
end

desc 'Seed service types'
task seed_service_types: [:environment, 'log:info_to_stdout'] do
  data_source_id = GrdaWarehouse::DataSource.hmis.first&.id
  next unless data_source_id.present?

  ::HmisUtil::ServiceTypes.seed_hud_service_types(data_source_id)
  ::HmisUtil::ServiceTypes.seed_hud_service_form_instances
end

desc 'Kick off job to create CustomAssessments by grouping related records'
task migrate_assessments: [:environment, 'log:info_to_stdout'] do
  GrdaWarehouse::DataSource.hmis.pluck(:id).each do |id|
    Hmis::MigrateAssessmentsJob.perform_later(data_source_id: id)
  end
end
