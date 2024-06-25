###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_form_definition, class: 'Hmis::Form::Definition' do
    version { 1 }
    sequence(:identifier) { |n| "form_#{n}" }
    role { 'UPDATE' }
    status { Hmis::Form::Definition::PUBLISHED }
    title { 'Form' }
    definition do
      {
        'item': [
          {
            'type': 'GROUP',
            'link_id': 'q1',
            'item': [
              {
                'type': 'DATE',
                'link_id': 'linkid_date',
                'required': true,
                'warn_if_empty': false,
                'text': 'Information Date',
                'assessment_date': true,
                'mapping': { 'field_name': 'informationDate' },
              },
              {
                'type': 'INTEGER',
                'link_id': 'linkid_required',
                'required': true,
                'warn_if_empty': false,
                'brief_text': 'The Required Field',
                'text': 'A required field',
                'mapping': { 'field_name': 'fieldOne' },
              },
              {
                'type': 'CHOICE',
                'link_id': 'linkid_choice',
                'required': false,
                'warn_if_empty': true,
                'text': 'Choice field',
                "pick_list_reference": 'NoYesMissing',
                'mapping': { 'field_name': 'fieldTwo' },
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
