FactoryBot.define do
  factory :hmis_form_definition, class: 'Hmis::Form::Definition' do
    version { 1 }
    sequence(:identifier, 1)
    role { 'INTAKE' }
    status { 'active' }
    definition do
      {
        'name': 'assessment-example',
        'item': [
          {
            'type': 'group',
            'linkId': 'initial-group',
            'item': [
              {
                'type': 'choice',
                'linkId': '3.15',
                'required': true,
                'text': 'Relationship to Head of Household',
                'answerValueSet': 'RelationshipToHoH',
              },
            ],
          },
        ],
      }
    end
  end
end
