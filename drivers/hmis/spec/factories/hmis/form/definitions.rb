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
  factory :custom_assessment_with_custom_fields, parent: :hmis_form_definition do
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
  end

  factory :hmis_external_form_definition_updates_client, parent: :hmis_external_form_definition do
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
                  "type": "STRING",
                  "link_id": "first_name",
                  "mapping": {
                    "field_name": "firstName",
                    "record_type": "CLIENT"
                  },
                  "text": "First name"
                },
                {
                  "type": "CHOICE",
                  "pick_list_reference": "RelationshipToHoH",
                  "link_id": "relationship_to_hoh",
                  "mapping": {
                    "field_name": "relationshipToHoH",
                    "record_type": "ENROLLMENT"
                  },
                  "text": "Relationship to HoH"
                },
                {
                  "type": "STRING",
                  "link_id": "household_id",
                  "mapping": {
                    "field_name": "householdId",
                    "record_type": "ENROLLMENT"
                  }
                },
                {
                  "type": "STRING",
                  "link_id": "veteran_status",
                  "mapping": {
                    "field_name": "veteranStatus",
                    "record_type": "CLIENT"
                  }
                },
                {
                  "type": "GEOLOCATION",
                  "link_id": "geolocation",
                  "mapping": {
                    "field_name": "coordinates",
                    "record_type": "GEOLOCATION"
                  }
                },
                {
                  "type": "CHOICE",
                  "pick_list_reference": "ClientAgeGroup",
                  "link_id": "how_old_are_you",
                  "mapping": {
                    "field_name": "ageRange",
                    "record_type": "CLIENT"
                  }
                },
                {
                  "text": "What is your Date of Birth?",
                  "type": "DATE",
                  "link_id": "client_dob",
                  "mapping": {
                    "field_name": "dob",
                    "record_type": "CLIENT"
                  }
                },
                {
                  "text": "Do you have a substance use disorder?",
                  "type": "CHOICE",
                  "link_id": "substance_use_disorder",
                  "mapping": {
                    "field_name": "substanceUseDisorder",
                    "record_type": "DISABILITY_GROUP"
                  },
                  "component": "RADIO_BUTTONS",
                  "disabled_display": "HIDDEN",
                  "pick_list_options": [
                    {
                      "code": "0",
                      "label": "No"
                    },
                    {
                      "code": "1",
                      "label": "Alcohol use disorder"
                    },
                    {
                      "code": "2",
                      "label": "Drug use disorder"
                    },
                    {
                      "code": "3",
                      "label": "Both alcohol and drug use disorders"
                    }
                  ]
                },
                {
                  "text": "Do you have an HIV related diagnosis?",
                  "type": "CHOICE",
                  "link_id": "hiv_aids",
                  "mapping": {
                    "field_name": "hivAids",
                    "record_type": "DISABILITY_GROUP"
                  },
                  "component": "RADIO_BUTTONS",
                  "disabled_display": "HIDDEN",
                  "pick_list_options": [
                    {
                      "code": "0",
                      "label": "No"
                    },
                    {
                      "code": "1",
                      "label": "Yes"
                    }
                  ]
                }
              ]
            }
          ]
        }
      JSON
    end
  end
end
