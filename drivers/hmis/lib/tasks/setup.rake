desc 'Seed form definitions'
task seed_definitions: [:environment, 'log:info_to_stdout'] do
  builder = ::HmisUtil::JsonForms.new
  builder.seed_all
  # In development, create the initial instances for occurrence-point collection.
  builder.create_default_occurrence_point_instances! if Rails.env.development?
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

# rake driver:hmis:generate_custom_data_elements[ALL,true] # dry-run generate CustomDataElements for all forms (no save)
# rake driver:hmis:generate_custom_data_elements[CUSTOM_ASSESSMENT,true]
# rake driver:hmis:generate_custom_data_elements[ALL]      # save CustomDataElements for all forms
# rake driver:hmis:generate_custom_data_elements[SERVICE]  # save CustomDataElements for one role
desc 'Generate Custom Data Elements by introspecting Form Definitions'
task :generate_custom_data_elements, [:role, :dry_run] => [:environment, 'log:info_to_stdout'] do |_task, args|
  raise 'role is required. pass ALL to generate for all roles' unless args.role

  dry_run = args.dry_run == 'true'
  puts 'Running a dry-run...' if dry_run

  role = args.role
  custom_data_element_definitions = []
  seen_keys = Set.new

  definition_scope = Hmis::Form::Definition.non_static
  definition_scope = definition_scope.with_role(role) if role != 'ALL'
  puts "#{definition_scope.size} forms to process: #{definition_scope.map(&:identifier).join(', ')}\n\n"

  definition_scope.order(:id).each do |definition|
    definition.introspect_custom_data_element_definitions.each do |cded|
      unique_key = [cded.owner_type, cded.key]
      next if seen_keys.include?(unique_key) # Already processed, skip

      seen_keys.add(unique_key)
      custom_data_element_definitions << cded
    end
  end

  custom_data_element_definitions.flatten!

  new_cdeds = custom_data_element_definitions.reject(&:persisted?)
  existing_cdeds = custom_data_element_definitions.select(&:persisted?)

  if dry_run
    puts "Found #{existing_cdeds.size} EXISTING keys"
    puts "Found #{new_cdeds.size} NEW keys"
    new_cdeds.each do |r|
      puts "   #{r.owner_type}; #{r.key}; #{r.field_type}; #{r.label}"
    end
    puts 'Exiting without saving.'
    next
  end

  Hmis::Hud::CustomDataElementDefinition.transaction do
    existing_cdeds.each(&:save!)
    new_cdeds.each(&:save!)
  end

  puts "Saved #{existing_cdeds.size} EXISTING keys: #{existing_cdeds.size > 50 ? 'truncated' : existing_cdeds.map(&:key)}"
  puts "Saved #{new_cdeds.size} NEW keys: #{new_cdeds.map(&:key)}"
end
