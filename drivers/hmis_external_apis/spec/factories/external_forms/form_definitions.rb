FactoryBot.define do
  factory :hmis_external_form_definition, parent: :hmis_form_definition do
    sequence(:external_form_object_key) do |n|
      "sample_external_form_#{n}"
    end
    role { 'EXTERNAL_FORM' }
    definition do
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
                  "text": "Your Name",
                  "mapping": {"custom_field_key": "your_name"}
                }
              ]
            }
          ]
        }
      JSON
    end
    transient do
      append_items { nil } # Items to append to FormDefinition content
    end
    after(:create) do |instance, evaluator|
      if evaluator.append_items
        instance.definition['item'][0]['item'].push(*Array.wrap(evaluator.append_items))
        instance.save!
      end
    end
  end
end
