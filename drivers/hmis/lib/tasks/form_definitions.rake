require 'json'

desc 'Seed form definitions for editing and creating records'
task seed_record_form_definitions: [:environment, 'log:info_to_stdout'] do
  forms = []
  Dir.glob('drivers/hmis/lib/form_data/records/*.json') do |file_path|
    identifier = File.basename(file_path, '.json')
    file = File.read(file_path)
    form_definition = JSON.parse(file)
    forms.push(identifier)

    definition = Hmis::Form::Definition.find_or_create_by(identifier: identifier)
    definition.definition = form_definition.to_json
    definition.version = 0
    definition.role = 'CUSTOM'
    definition.status = 'draft'
    definition.save!
  end
  puts "Saved definitions with these identifiers: #{forms}"
end

desc 'Seed default form definition for intake assessments'
task seed_assessment_form_definitions: [:environment, 'log:info_to_stdout'] do
  file = File.read('drivers/hmis/lib/form_data/assessments/dummy_intake_assessment.json')
  form_definition = JSON.parse(file)
  identifier = 'dummy-intake-assessment'
  definition = Hmis::Form::Definition.find_or_create_by(identifier: identifier)
  definition.definition = form_definition.to_json
  definition.version = 0
  definition.role = 'INTAKE'
  definition.status = 'draft'
  definition.save!

  # Make this form the fallback instance for all intake assessments
  instance = Hmis::Form::Instance.find_or_create_by(entity_type: nil, entity_id: nil)
  instance.definition_identifier = identifier
  instance.save!
end
