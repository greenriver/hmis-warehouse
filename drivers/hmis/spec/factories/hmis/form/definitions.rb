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
                'pick_list_reference': 'NoYesMissing',
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
        item: [
          {
            type: 'DATE',
            link_id: 'exit_date',
            required: true,
            warn_if_empty: false,
            assessment_date: true,
            mapping: {
              record_type: 'EXIT',
              field_name: 'exitDate',
            },
          },
        ],
      }
    end
  end

  factory :housing_needs_assessment, parent: :hmis_form_definition do
    role { :CUSTOM_ASSESSMENT }
    definition do
      {
        'item': [
          {
            'type': 'GROUP',
            'text': 'TEST Housing Needs Assessment',
            'link_id': 'housing_needs_assessment_example_group',
            'item': [
              {
                'type': 'DATE',
                'required': true,
                'link_id': 'q_4_19_1',
                'text': 'Assessment Date',
                'assessment_date': true,
                'mapping': {
                  'record_type': 'ASSESSMENT',
                  'field_name': 'assessmentDate',
                },
              },
              {
                'type': 'TEXT',
                'required': true,
                'link_id': 'q_4_19_2',
                'text': 'Assessment Location',
                'mapping': {
                  'record_type': 'ASSESSMENT',
                  'field_name': 'assessmentLocation',
                },
              },
              {
                'type': 'CHOICE',
                'required': true,
                'text': 'Assessment Type',
                'pick_list_reference': 'AssessmentType',
                'link_id': 'q_4_19_3',
                'mapping': {
                  'record_type': 'ASSESSMENT',
                  'field_name': 'assessmentType',
                },
              },
              {
                'type': 'CHOICE',
                'required': true,
                'text': 'Assessment Level',
                'pick_list_reference': 'AssessmentLevel',
                'link_id': 'q_4_19_4',
                'mapping': {
                  'record_type': 'ASSESSMENT',
                  'field_name': 'assessmentLevel',
                },
              },
              {
                'type': 'CHOICE',
                'required': true,
                'text': 'Prioritization Status',
                'pick_list_reference': 'PrioritizationStatus',
                'link_id': 'q_4_19_7',
                'mapping': {
                  'record_type': 'ASSESSMENT',
                  'field_name': 'prioritizationStatus',
                },
              },
              {
                'text': 'TEST assessment question',
                'type': 'TEXT',
                'link_id': 'A1',
                'mapping': {
                  'custom_field_key': 'assessment_question',
                },
              },
            ],
          },
        ],
      }
    end

    # This factory could create the `assessment_question` CDED using after_create, but for now it's not needed
  end

  factory :custom_assessment_with_custom_fields_and_rules, parent: :hmis_form_definition do
    role { :CUSTOM_ASSESSMENT }
    definition do
      {
        'item': [
          {
            'type': 'GROUP',
            'text': 'Test Custom Assessment',
            'link_id': 'section_1',
            'item': [
              {
                'type': 'DATE',
                'required': true,
                'link_id': 'assessment_date',
                'text': 'Assessment Date',
                'assessment_date': true,
                'mapping': {
                  'field_name': 'assessmentDate',
                },
              },
              {
                'type': 'STRING',
                'required': true,
                'link_id': 'es_projects_custom_question',
                'text': 'Custom field for ES projects only',
                'mapping': {
                  'custom_field_key': 'es_projects_custom_question',
                },
                'rule': {
                  operator: 'ANY',
                  parts: [
                    {
                      variable: 'projectType',
                      operator: 'EQUAL',
                      value: 1, # ES NBN
                    },
                  ],
                },
              },
              {
                'type': 'STRING',
                'required': true,
                'link_id': 'veteran_hoh_custom_question',
                'text': 'Custom field for Veteran HoH only',
                'mapping': {
                  'custom_field_key': 'veteran_hoh_custom_question',
                },
                data_collected_about: 'VETERAN_HOH',
              },
            ],
          },
        ],
      }.deep_stringify_keys
    end
    transient do
      data_source { nil }
    end
    after(:create) do |_instance, evaluator|
      next unless evaluator.data_source # must pass data source to create CDEDs

      Hmis::Hud::CustomDataElementDefinition.where(
        owner_type: 'Hmis::Hud::CustomAssessment',
        key: :es_projects_custom_question,
        label: 'Custom field for ES projects only',
        field_type: :string,
        data_source: evaluator.data_source,
        UserID: '1',
      ).first_or_create!

      Hmis::Hud::CustomDataElementDefinition.where(
        owner_type: 'Hmis::Hud::CustomAssessment',
        key: :veteran_hoh_custom_question,
        label: 'Custom field for Veteran HoH only',
        field_type: :string,
        data_source: evaluator.data_source,
        UserID: '1',
      ).first_or_create!
    end
  end
end
