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
                'text': 'Assessment Date',
                'assessment_date': true,
                'mapping': { 'field_name': 'assessmentDate' },
              },
              {
                'type': 'INTEGER',
                'link_id': 'linkid_required',
                'required': true,
                'warn_if_empty': false,
                'brief_text': 'The Required Field',
                'text': 'A required field',
                'mapping': { 'custom_field_key': 'fieldOne' },
              },
              {
                'type': 'CHOICE',
                'link_id': 'linkid_choice',
                'required': false,
                'warn_if_empty': true,
                'text': 'Choice field',
                'pick_list_reference': 'NoYesMissing',
                'mapping': { 'custom_field_key': 'fieldTwo' },
              },
            ],
          },
        ],
      }
    end
    transient do
      data_source { nil } # Data source needed to create CDEDs
      append_items { nil } # Items to append to FormDefinition content
    end
    after(:create) do |instance, evaluator|
      if evaluator.append_items
        instance.definition['item'][0]['item'].push(*Array.wrap(evaluator.append_items))
        instance.save!
      end

      next unless instance.published? && evaluator.data_source

      # Create CDEDs for items that have { mapping: { custom_field_key: '...' } }
      # Note: this is slightly different from the CDED generation process that happens on publish,
      # which does not expect any `mapping` to be present on new items.
      instance.introspect_custom_data_element_definitions(set_definition_identifier: true, data_source: evaluator.data_source).reject(&:persisted?).each(&:save!)
    end
  end

  factory :hmis_intake_assessment_definition, parent: :hmis_form_definition do
    role { :INTAKE }
    definition do
      {
        'item': [
          {
            'type': 'GROUP',
            'text': 'Test Intake Assessment',
            'link_id': 'section_1',
            'item': [
              {
                'type': 'DATE',
                'link_id': 'entryDate',
                'required': true,
                'warn_if_empty': false,
                'assessment_date': true,
                'text': 'Entry Date',
                'mapping': {
                  'record_type': 'ENROLLMENT',
                  'field_name': 'entryDate',
                },
              },
            ],
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

  # Custom Assessment that create/updates a CE Assessment record
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
                  'record_type': 'ASSESSMENT', # CeAssessment
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
  end

  # Custom Assessment that creates/updates a Custom Data Element
  factory :custom_assessment_with_custom_fields_and_rules, parent: :hmis_form_definition do
    role { :CUSTOM_ASSESSMENT }
    title { 'Test Custom Assessment' }
    sequence(:identifier) { |n| "custom_assessment_#{n}" }
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
                'required': false,
                'link_id': 'custom_question_1',
                'text': 'Custom question 1',
                'mapping': {
                  'custom_field_key': 'custom_question_1',
                },
              },
            ],
          },
        ],
      }.deep_stringify_keys
    end
  end

  # Custom Assessment that has advanced features that aren't available to all users
  factory :custom_assessment_with_field_rules_and_autofill, parent: :hmis_form_definition do
    role { :CUSTOM_ASSESSMENT }
    title { 'Advanced Assessment' }
    sequence(:identifier) { |n| "custom_assessment_#{n}" }
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
                'text': 'Yes or no?',
                'type': 'BOOLEAN',
                'link_id': 'yes_or_no',
                'mapping': {
                  'custom_field_key': 'yes_or_no',
                },
              },
              {
                'text': 'Conditionally autofilled',
                'type': 'STRING',
                'link_id': 'conditionally_autofilled',
                'mapping': {
                  'custom_field_key': 'conditionally_autofilled',
                },
                'autofill_values': [
                  {
                    'value_code': 'filled',
                    'autofill_when': [
                      {
                        'operator': 'EQUAL',
                        'question': 'yes_or_no',
                        'answer_boolean': true,
                      },
                    ],
                    'autofill_behavior': 'ALL',
                    'autofill_readonly': false,
                  },
                ],
                'custom_rule': {
                  'variable': 'projectId',
                  'operator': 'NOT_EQUAL',
                  'value': 'some-particular-project-id',
                },
              },
            ],
          },
        ],
      }.deep_stringify_keys
    end
  end
end
