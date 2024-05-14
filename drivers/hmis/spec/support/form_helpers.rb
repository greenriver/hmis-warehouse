###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module FormHelpers
  def build_minimum_values(definition, assessment_date: nil, values: {}, hud_values: {})
    assessment_date ||= Date.yesterday.strftime('%Y-%m-%d')

    date_item = definition.assessment_date_item
    date_field = date_item.mapping.field_name
    date_field = "Exit.#{date_field}" if definition.exit?
    date_field = "Enrollment.#{date_field}" if definition.intake?

    values = { date_item.link_id => assessment_date, **values.stringify_keys }
    hud_values = { date_field => assessment_date, **hud_values.stringify_keys }
    hud_values['Exit.destination'] = 'SAFE_HAVEN' if definition.exit?

    {
      values: values,
      hud_values: hud_values,
    }
  end

  def find_required_item(definition)
    definition.link_id_item_hash.find { |_link_id, item| item.required && item.mapping&.field_name&.present? }&.last
  end

  def add_item_to_definition(definition, item)
    definition.definition['item'] << item
    definition.save!
    definition
  end

  # get mocked "hud_values" (keyed by field name) and generate "values" (keyed by link id)
  def mock_form_values_for_definition(definition)
    hud_values = COMPLETE_VALUES[definition.role.to_sym]
    values_by_link_id = {}

    # hack: convert 'Client.firstName'=>'firstName' because we know the field names are not duplicated
    # across record types in the mocks..
    hud_values_keys_by_fname = hud_values.transform_keys { |k| k.split('.').last }

    # generate the value map {LinkID=>value} containing each mocked value
    definition.link_id_item_hash.each do |link_id, item|
      next unless item.mapping&.field_name.present?
      next unless hud_values_keys_by_fname.key?(item.mapping.field_name)

      value = hud_values_keys_by_fname[item.mapping.field_name]
      values_by_link_id[link_id] = value unless value == '_HIDDEN'
    end

    result = {
      values: values_by_link_id,
      hud_values: hud_values,
    }

    yield(result) if block_given?

    result
  end

  # Mock data representing a submitted form for each form role.
  # These are not meant to be comprehensive, the Form Processor tests have more coverage for form processing.
  COMPLETE_VALUES = {
    PROJECT: {
      'projectName' => 'Test Project',
      'description' => 'project description',
      'contactInformation' => 'contact info',
      'operatingStartDate' => '2023-01-13',
      'operatingEndDate' => '2023-01-28',
      'projectType' => 'ES_NBN',
      'residentialAffiliation' => 'NO',
      'housingType' => 'SITE_BASED_SINGLE_SITE',
      'targetPopulation' => 'HIV_PERSONS_WITH_HIV_AIDS',
      'HOPWAMedAssistedLivingFac' => 'NO',
      'continuumProject' => 'NO',
    },
    CLIENT: {
      'names' => [
        {
          "first": 'First',
          "middle": 'Middle',
          "last": 'Last',
          "suffix": 'Sf',
          "nameDataQuality": 'FULL_NAME_REPORTED',
          "use": nil,
          "notes": nil,
          "primary": true,
        },

      ],
      'dob' => '2000-03-29',
      'dobDataQuality' => 'FULL_DOB_REPORTED',
      'ssn' => 'XXXXX1234',
      'ssnDataQuality' => 'APPROXIMATE_OR_PARTIAL_SSN_REPORTED',
      'race' => [
        'WHITE',
        'ASIAN',
      ],
      'gender' => [
        'WOMAN',
        'TRANSGENDER',
      ],
      'pronouns' => [
        'she/her',
      ],
      'veteranStatus' => 'CLIENT_PREFERS_NOT_TO_ANSWER',
      'imageBlobId' => nil,

    },
    FUNDER: {
      'funder' => 'HUD_COC_TRANSITIONAL_HOUSING',
      'otherFunder' => '_HIDDEN',
      'grantId' => 'ABCDEF',
      'startDate' => '2022-12-01',
      'endDate' => '2023-03-24',
    },
    PROJECT_COC: {
      'cocCode' => 'MA-504',
      'geocode' => '250354',
      'geographyType' => 'SUBURBAN',
      'address1' => '1 State Street',
      'address2' => nil,
      'city' => 'Brockton',
      'state' => 'MA',
      'zip' => '12345',
    },
    INVENTORY: {
      'cocCode' => 'CO-500',
      'householdType' => 'HOUSEHOLDS_WITH_AT_LEAST_ONE_ADULT_AND_ONE_CHILD',
      'availability' => 'SEASONAL',
      'esBedType' => 'OTHER',
      'inventoryStartDate' => '2023-01-23',
      'inventoryEndDate' => '2023-01-28',
      'unitInventory' => 0,
      'bedInventory' => 0,
    },
    ORGANIZATION: {
      'organizationName' => 'Test org',
      'description' => 'description',
      'contactInformation' => nil,
      'victimServiceProvider' => 'NO',
    },
    SERVICE: {
      'otherTypeProvided' => '_HIDDEN',
      'movingOnOtherType' => 'something',
      'subTypeProvided' => '_HIDDEN',
      'faAmount' => '_HIDDEN',
      'faStartDate' => '_HIDDEN',
      'referralOutcome' => '_HIDDEN',
      'dateProvided' => '2023-03-15',
    },
    FILE: {
      'confidential' => false,
      'enrollmentId' => nil,
      # tags and file blob are also required, but not included here since they need to reference something real

    },
    ENROLLMENT: {
      'entryDate' => Date.yesterday.strftime('%Y-%m-%d'),
      'relationshipToHoH' => 'SELF_HEAD_OF_HOUSEHOLD',
      'enrollmentCoc' => 'XX-500',
    },
    NEW_CLIENT_ENROLLMENT: {
      'Client.firstName' => 'First',
      'Client.lastName' => 'Last',
      'Client.nameDataQuality' => 'FULL_NAME_REPORTED',
      'Client.dob' => '2000-03-29',
      'Client.dobDataQuality' => 'FULL_DOB_REPORTED',
      'Client.ssn' => 'XXXXX1234',
      'Client.ssnDataQuality' => 'APPROXIMATE_OR_PARTIAL_SSN_REPORTED',
      'Client.race' => ['WHITE', 'ASIAN'],
      'Client.gender' => ['WOMAN', 'TRANSGENDER'],
      'Client.veteranStatus' => 'CLIENT_PREFERS_NOT_TO_ANSWER',
      'Enrollment.entryDate' => '2023-09-07',
      'Enrollment.relationshipToHoH' => 'SELF_HEAD_OF_HOUSEHOLD',
    },
    CURRENT_LIVING_SITUATION: {
      'informationDate' => '2023-07-27',
      'currentLivingSituation' => 'FOSTER_CARE_HOME_OR_FOSTER_CARE_GROUP_HOME',
      'clsSubsidyType' => '_HIDDEN',
      'leaveSituation14Days' => 'YES',
      'subsequentResidence' => 'NO',
      'resourcesToObtain' => 'CLIENT_PREFERS_NOT_TO_ANSWER',
      'leaseOwn60Day' => 'CLIENT_DOESN_T_KNOW',
      'movedTwoOrMore' => 'YES',
      'locationDetails' => 'test',
    },
    CE_ASSESSMENT: {
      'assessmentDate' => '2023-08-15',
      'assessmentLocation' => 'test',
      'assessmentType' => 'PHONE',
      'assessmentLevel' => 'CRISIS_NEEDS_ASSESSMENT',
      'prioritizationStatus' => 'PLACED_ON_PRIORITIZATION_LIST',
    },
    CE_EVENT: {
      'eventDate' => '2023-08-12',
      'event' => 'REFERRAL_TO_JOINT_TH_RRH_PROJECT_UNIT_RESOURCE_OPENING',
      'probSolDivRrResult' => '_HIDDEN',
      'referralCaseManageAfter' => '_HIDDEN',
      'locationCrisisOrPhHousing' => 'test',
      'referralResult' => 'SUCCESSFUL_REFERRAL_CLIENT_ACCEPTED',
      'resultDate' => '2023-08-16',
    },
    CASE_NOTE: {
      content: 'test',
    }.stringify_keys,
    HMIS_PARTICIPATION: {
      "hmisParticipationType": 'HMIS_PARTICIPATING',
      "hmisParticipationStatusStartDate": '2020-07-19',
      "hmisParticipationStatusEndDate": nil,
    }.stringify_keys,
    CE_PARTICIPATION: {
      "accessPoint": 'YES',
      "preventionAssessment": 'YES',
      "crisisAssessment": 'YES',
      "housingAssessment": 'YES',
      "directServices": 'YES',
      "receivesReferrals": 'YES',
      "ceParticipationStatusStartDate": '2020-07-01',
      "ceParticipationStatusEndDate": nil,
    }.stringify_keys,
  }.freeze
end
