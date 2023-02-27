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
                'warn_if_empty': false,
                'text': 'Information Date',
                'assessment_date': true,
                'field_name': 'informationDate',
              },
              {
                'type': 'NUMBER',
                'link_id': 'linkid-required',
                'required': true,
                'warn_if_empty': false,
                'brief_text': 'The Required Field',
                'field_name': 'fieldOne',
              },
              {
                'type': 'CHOICE',
                'link_id': 'linkid-choice',
                'required': false,
                'warn_if_empty': true,
                'text': 'Choice field',
                'field_name': 'fieldTwo',
              },
            ],
          },
        ],
      }.to_json
    end
  end
end
