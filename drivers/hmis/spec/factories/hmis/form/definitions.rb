FactoryBot.define do
  factory :hmis_form_definition, class: 'Hmis::Form::Definition' do
    version { 1 }
    sequence(:identifier, 100)
    role { 'INTAKE' }
    status { 'active' }
    definition do
      {
        'item': [
          {
            'type': 'GROUP',
            'link_id': '1',
            'item': [
              {
                'type': 'CHOICE',
                'link_id': '2',
                'required': true,
                'text': 'Relationship to Head of Household',
                'pick_list_reference': 'RelationshipToHoH',
              },
              {
                'type': 'CHOICE',
                'link_id': '3',
                'required': false,
                'text': 'Some choice q',
                'pick_list_options': [
                  { 'code': 'a', 'label': 'Label' },
                  { 'code': 'b', 'label': 'Label 2' },
                ],
              },
            ],
          },
        ],
      }.to_json
    end
  end
end
