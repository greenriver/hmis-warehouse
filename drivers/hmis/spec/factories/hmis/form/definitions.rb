FactoryBot.define do
  factory :hmis_form_definition, class: 'Hmis::Form::Definition' do
    version { 1 }
    sequence(:identifier, 100)
    role { 'UPDATE' }
    status { 'active' }
    definition do
      {
        'item': [
          {
            'type': 'GROUP',
            'link_id': '1',
            'item': [
              {
                'type': 'DATE',
                'link_id': 'linkid-date',
                'required': true,
                'text': 'Information Date',
                'assessment_date': true,
                'field_name': 'informationDate',
              },
              {
                'type': 'STRING',
                'link_id': 'linkid-1',
                'field_name': 'fieldOne',
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
