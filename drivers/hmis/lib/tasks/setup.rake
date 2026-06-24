desc 'Seed form definitions'
task seed_definitions: [:environment, 'log:info_to_stdout'] do
  GrdaWarehouse::DataSource.hmis.pluck(:id, :name).each do |data_source_id, name|
    puts "Seeding form definitions for DS##{data_source_id} #{name}"
    ::HmisUtil::JsonForms.seed_all(data_source_id: data_source_id)
  end
end

desc 'Seed service types'
task seed_service_types: [:environment, 'log:info_to_stdout'] do
  GrdaWarehouse::DataSource.hmis.pluck(:id).each do |data_source_id|
    # Create 1 CustomServiceCategory per HUD RecordType, and
    # 1 CustomServiceType per HUD TypeProvided
    ::HmisUtil::ServiceTypes.seed_hud_service_types(data_source_id)
  end
end

desc 'Kick off job to create CustomAssessments by grouping related records'
task migrate_assessments: [:environment, 'log:info_to_stdout'] do
  GrdaWarehouse::DataSource.hmis.pluck(:id).each do |id|
    Hmis::MigrateAssessmentsJob.perform_later(data_source_id: id)
  end
end
