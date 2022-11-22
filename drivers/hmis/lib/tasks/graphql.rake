require 'digest/sha1'

desc 'Update schema.graphql dump'
task dump_graphql_schema: [:environment, 'log:info_to_stdout'] do
  schema_definition = HmisSchema.to_definition
  schema_path = Rails.root.join('drivers', 'hmis', 'app', 'graphql', 'schema.graphql')

  old_sha = Digest::SHA1.hexdigest(File.read(schema_path))

  File.write(schema_path, schema_definition)

  new_sha = Digest::SHA1.hexdigest(File.read(schema_path))
  if old_sha != new_sha
    # Use 'abort' to exit with status code 1, to indicate that the schema has changed
    abort "Updated #{schema_path}"
  else
    puts 'Schema unchanged.'
  end
end

desc 'Generate GraphQL Enums'
task generate_graphql_enums: [:environment, 'log:info_to_stdout'] do
  source = File.read('lib/data/hud_lists.json')
  skipped = ['race', '3.6.1', '2.4.2', '1.6']
  filename = 'drivers/hmis/app/graphql/types/hmis_schema/enums/hud.rb'

  seen = []
  arr = []
  arr.push ::Code.copywright_header
  arr.push "# frozen_string_literal: true\n"
  arr.push "# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY\n"
  arr.push 'module Types::HmisSchema::Enums::Hud'
  JSON.parse(source).each do |element|
    next if skipped.include?(element['code'].to_s)

    name = element['name']
    next if seen.include?(name)

    arr.push "  class #{name} < Types::BaseEnum"
    arr.push "    description '#{element['code'] || name}'"
    arr.push "    graphql_name '#{name}'"
    arr.push "    hud_enum ::HudLists.#{name.underscore}_map"
    arr.push '  end'
    seen << name
  end

  arr.push 'end'
  contents = arr.join("\n")
  File.open(filename, 'w') do |f|
    f.write(contents)
  end
  exec("bundle exec rubocop -A --format simple #{filename}")
end

desc 'Seed form definitions'
task seed_definitions: [:environment, 'log:info_to_stdout'] do
  seed_record_form_definitions
  seed_assessment_form_definitions
end

# Seed form definitions for editing and creating records
def seed_record_form_definitions
  forms = []
  Dir.glob('drivers/hmis/lib/form_data/records/*.json') do |file_path|
    identifier = File.basename(file_path, '.json')
    file = File.read(file_path)
    form_definition = JSON.parse(file)
    forms.push(identifier)

    definition = Hmis::Form::Definition.find_or_create_by(
      identifier: identifier,
      version: 0,
      role: 'RECORD',
      status: 'draft',
    )
    definition.definition = form_definition.to_json
    definition.save!
  end
  puts "Saved definitions with these identifiers: #{forms}"
end

# Seed default form definition for intake assessments
def seed_assessment_form_definitions
  file = File.read('drivers/hmis/lib/form_data/assessments/dummy_intake_assessment.json')
  form_definition = JSON.parse(file)
  Hmis::Form::Definition.validate_json(form_definition)

  identifier = 'dummy-intake-assessment'
  definition = Hmis::Form::Definition.find_or_create_by(
    identifier: identifier,
    version: 0,
    role: 'INTAKE',
    status: 'draft',
  )
  definition.definition = form_definition.to_json
  definition.save!

  # Make this form the fallback instance for all intake assessments
  instance = Hmis::Form::Instance.find_or_create_by(entity_type: nil, entity_id: nil)
  instance.definition_identifier = identifier
  instance.save!
end
