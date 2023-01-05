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

def seed_assessment_form_definitions
  # Load fragments
  fragment_map = {}
  Dir.glob('drivers/hmis/lib/form_data/fragments/*.json') do |file_path|
    identifier = File.basename(file_path, '.json')
    file = File.read(file_path)
    fragment_map["##{identifier}"] = JSON.parse(file)
  end

  roles = [:INTAKE, :EXIT, :UPDATE, :ANNUAL]
  roles.each do |role|
    file = File.read("drivers/hmis/lib/form_data/assessments/base_#{role.to_s.downcase}.json")
    next unless file.present?

    # Replace fragment references in JSON
    form_definition = JSON.parse(file)
    form_definition['item'].each_with_index do |item, idx|
      next unless item['fragment']

      fragment = fragment_map[item['fragment']]
      raise "Fragment not found #{item['fragment']}" unless fragment.present?

      form_definition['item'][idx] = fragment
    end

    # Validate form structure
    Hmis::Form::Definition.validate_json(form_definition)

    # Load definition into database
    identifier = "base-#{role.to_s.downcase}"
    definition = Hmis::Form::Definition.find_or_create_by(
      identifier: identifier,
      version: 0,
      role: role,
      status: 'draft',
    )
    definition.definition = form_definition.to_json
    definition.save!

    # Make this form the default instance for this role
    instance = Hmis::Form::Instance.find_or_create_by(entity_type: nil, entity_id: nil, definition_identifier: identifier)
    instance.save!
  end
end
