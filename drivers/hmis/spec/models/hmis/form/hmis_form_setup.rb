###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
end

RSpec.configure do |rspec|
  rspec.include_context 'hmis form setup', include_shared: true
end
