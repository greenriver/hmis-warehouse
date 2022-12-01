RSpec.shared_context 'hmis form setup', shared_context: :metadata do
  let!(:base_assessment_form_definition) do
    definition = File.read('drivers/hmis/lib/form_data/assessments/base_assessment.json')
    Hmis::Form::Definition.validate_json(JSON.parse(definition))
    create :hmis_form_definition, identifier: 'assessment', role: 'INTAKE', definition: definition
  end
  let!(:client_form_definition) do
    definition = File.read('drivers/hmis/lib/form_data/records/client.json')
    Hmis::Form::Definition.validate_json(JSON.parse(definition))
    create :hmis_form_definition, identifier: 'client', role: 'RECORD', definition: definition
  end
  let!(:organization_form_definition) do
    definition = File.read('drivers/hmis/lib/form_data/records/organization.json')
    Hmis::Form::Definition.validate_json(JSON.parse(definition))
    create :hmis_form_definition, identifier: 'organization', role: 'RECORD', definition: definition
  end
  let!(:project_form_definition) do
    definition = File.read('drivers/hmis/lib/form_data/records/project.json')
    Hmis::Form::Definition.validate_json(JSON.parse(definition))
    create :hmis_form_definition, identifier: 'project', role: 'RECORD', definition: definition
  end
  let!(:project_coc_form_definition) do
    definition = File.read('drivers/hmis/lib/form_data/records/project_coc.json')
    Hmis::Form::Definition.validate_json(JSON.parse(definition))
    create :hmis_form_definition, identifier: 'project_coc', role: 'RECORD', definition: definition
  end
  let!(:funder_form_definition) do
    definition = File.read('drivers/hmis/lib/form_data/records/funder.json')
    Hmis::Form::Definition.validate_json(JSON.parse(definition))
    create :hmis_form_definition, identifier: 'funder', role: 'RECORD', definition: definition
  end
  let!(:inventory_form_definition) do
    definition = File.read('drivers/hmis/lib/form_data/records/inventory.json')
    Hmis::Form::Definition.validate_json(JSON.parse(definition))
    create :hmis_form_definition, identifier: 'inventory', role: 'RECORD', definition: definition
  end
  let!(:search_form_definition) do
    definition = File.read('drivers/hmis/lib/form_data/records/search.json')
    Hmis::Form::Definition.validate_json(JSON.parse(definition))
    create :hmis_form_definition, identifier: 'search', role: 'RECORD', definition: definition
  end

  let(:form_item_fragment) do
    <<~GRAPHQL
      #{scalar_fields(Types::Forms::FormItem)}
      pickListOptions {
        #{scalar_fields(Types::Forms::PickListOption)}
      }
      bounds {
        #{scalar_fields(Types::Forms::ValueBound)}
      }
      enableWhen {
        #{scalar_fields(Types::Forms::EnableWhen)}
      }
      initial {
        #{scalar_fields(Types::Forms::InitialValue)}
      }
      autofillValues {
        #{scalar_fields(Types::Forms::AutofillValue)}
        autofillWhen {
          #{scalar_fields(Types::Forms::EnableWhen)}
        }
      }
    GRAPHQL
  end

  let(:form_definition_fragment) do
    <<~GRAPHQL
      #{scalar_fields(Types::Forms::FormDefinition)}
      definition {
        item {
          #{form_item_fragment}
          item {
            #{form_item_fragment}
            item {
              #{form_item_fragment}
              item {
                #{form_item_fragment}
              }
            }
          }
        }
      }
    GRAPHQL
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'hmis form setup', include_shared: true
end
