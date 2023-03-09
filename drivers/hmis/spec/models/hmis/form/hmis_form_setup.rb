RSpec.shared_context 'hmis form setup', shared_context: :metadata do
  before(:all) do
    system 'RAILS_ENV=test bin/rake driver:hmis:seed_definitions'
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

  let(:complete_project_values) do
    {
      "2.02.2": 'Test Project',
      "description": nil,
      "contact": nil,
      "2.02.3": '2023-01-13T05:00:00.000Z',
      "2.02.4": '2023-01-28T05:00:00.000Z',
      "2.02.6": {
        "code": 'ES',
        "label": 'Emergency Shelter',
      },
      "2.02.C": {
        "code": 'NIGHT_BY_NIGHT',
        "label": 'Night-by-Night',
      },
      "2.02.D": {
        "code": 'SITE_BASED_SINGLE_SITE',
        "label": 'Site-based - single site',
      },
      "2.02.8": {
        "code": 'PERSONS_WITH_HIV_AIDS',
        "label": 'Persons with HIV/AIDS',
      },
      "2.02.9": {
        "code": 'NO',
        "label": 'No',
      },
      "2.02.5": nil,
      "2.02.7": nil,
    }
  end

  let(:complete_project_hud_values) do
    {
      "projectName": 'Test Project',
      "description": nil,
      "contactInformation": nil,
      "operatingStartDate": '2023-01-13',
      "operatingEndDate": '2023-01-28',
      "projectType": 'ES',
      "trackingMethod": 'NIGHT_BY_NIGHT',
      "residentialAffiliation": nil,
      "housingType": 'SITE_BASED_SINGLE_SITE',
      "targetPopulation": 'PERSONS_WITH_HIV_AIDS',
      "HOPWAMedAssistedLivingFac": 'NO',
      "continuumProject": false,
      "HMISParticipatingProject": true,
    }
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'hmis form setup', include_shared: true
end
