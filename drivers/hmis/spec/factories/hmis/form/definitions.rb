###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_form_definition, class: 'Hmis::Form::Definition' do
    version { 1 }
    sequence(:identifier, 100)
    role { 'UPDATE' }
    status { Hmis::Form::Definition::PUBLISHED }
    title { 'Form' }
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
                'mapping': { 'field_name': 'informationDate', 'custom_field_key': 'informationDate' },
              },
              {
                'type': 'NUMBER',
                'link_id': 'linkid-required',
                'required': true,
                'warn_if_empty': false,
                'brief_text': 'The Required Field',
                'mapping': { 'field_name': 'fieldOne', 'custom_field_key': 'fieldOne' },
              },
              {
                'type': 'CHOICE',
                'link_id': 'linkid-choice',
                'required': false,
                'warn_if_empty': true,
                'text': 'Choice field',
                'mapping': { 'field_name': 'fieldTwo', 'custom_field_key': 'fieldTwo' },
              },
            ],
          },
        ],
      }
    end
  end

  factory :hmis_intake_assessment_definition, parent: :hmis_form_definition do
    role { :INTAKE }
    definition do
      {
        'item': [
          {
            'type': 'DATE',
            'link_id': 'date',
            'required': true,
            'warn_if_empty': false,
            'assessment_date': true,
            'mapping': { 'field_name': 'entryDate' },
          },
        ],
      }
    end
  end

  factory :hmis_exit_assessment_definition, parent: :hmis_form_definition do
    role { :EXIT }
    definition do
      {
        'item': [
          {
            'type': 'DATE',
            'link_id': 'date',
            'required': true,
            'warn_if_empty': false,
            'assessment_date': true,
            'mapping': { 'field_name': 'exitDate' },
          },
        ],
      }
    end
  end
end
