
FactoryBot.define do
  factory :hmis_external_apis_external_form_definition, class: 'HmisExternalApis::ExternalForms::FormDefinition' do
    sequence(:name) { |n| "form_#{n}" }
    sequence(:title) { |n| "Form #{n}" }
    data do
      JSON.parse(<<~JSON)
        {
          "name": "Test form",
          "item": [
            {
              "type": "GROUP",
              "link_id": "group_1",
              "text": "Test group",
              "item": [
                {
                  "link_id": "your_name",
                  "required": true,
                  "type": "STRING",
                  "text": "Your Name"
                },
                {
                  "link_id": "display_1",
                  "type": "DISPLAY",
                  "text": "Some informational content here"
                },
                {
                  "link_id": "a_radio_choice",
                  "required": true,
                  "type": "CHOICE",
                  "component": "RADIO_BUTTONS",
                  "text": "Are you testing a form?",
                  "pick_list_options": [
                    {
                      "code": "yes",
                      "label": "Yes"
                    },
                    {
                      "code": "no",
                      "label": "No"
                    }
                  ]
                },
                {
                  "link_id": "a_select_choice",
                  "type": "CHOICE",
                  "component": "DROPDOWN",
                  "text": "How many tests?",
                  "pick_list_options": [
                    {
                      "code": "not_many",
                      "label": "Not many"
                    },
                    {
                      "code": "a_whole_bunch",
                      "label": "A whole bunch"
                    }
                  ]
                },
                {
                  "link_id": "a_checkbox",
                  "type": "BOOLEAN",
                  "component": "CHECKBOX",
                  "text": "I understand that this is a test"
                }
              ]
            }
          ]
        }
      JSON
    end
  end
end
