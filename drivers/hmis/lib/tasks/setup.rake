desc 'Seed form definitions'
task seed_definitions: [:environment, 'log:info_to_stdout'] do
  ::HmisUtil::JsonForms.seed_record_form_definitions
  ::HmisUtil::JsonForms.seed_assessment_form_definitions
end

desc 'Load a particular definition'
# rails driver:hmis:load_definition identifier=esg_funding_service role=SERVICE
task :load_definition, [:identifier, :role] => [:environment, 'log:info_to_stdout'] do |_t, args|
  ::HmisUtil::JsonForms.load_definition(args[:identifier], role: args[:role])
end

desc 'Seed service types'
task seed_service_types: [:environment, 'log:info_to_stdout'] do
  data_source_id = GrdaWarehouse::DataSource.hmis.first&.id
  next unless data_source_id.present?

  ::HmisUtil::ServiceTypes.seed_hud_service_types(data_source_id)
  ::HmisUtil::ServiceTypes.seed_hud_service_form_instances
end
