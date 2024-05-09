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

  def completed_form_values_for_role(role)
    yield(COMPLETE_VALUES[role]) if block_given?

    COMPLETE_VALUES[role]
  end

  COMPLETE_VALUES = {
    PROJECT: {
      values: {
        '2.02.2' => 'Test Project',
        'description' => nil,
        'contact' => nil,
        '2.02.3' => '2023-01-13T05:00:00.000Z',
        '2.02.4' => '2023-01-28T05:00:00.000Z',
        '2.02.6' => 'ES_NBN',
        '2.02.D' => 'SITE_BASED_SINGLE_SITE',
        '2.02.7' => 'HIV_PERSONS_WITH_HIV_AIDS',
        '2.02.8' => 'NO',
        '2.02.5' => 'NO',
      },
      hud_values: {
        'projectName' => 'Test Project',
        'description' => nil,
        'contactInformation' => nil,
        'operatingStartDate' => '2023-01-13',
        'operatingEndDate' => '2023-01-28',
        'projectType' => 'ES_NBN',
        'residentialAffiliation' => nil,
        'housingType' => 'SITE_BASED_SINGLE_SITE',
        'targetPopulation' => 'HIV_PERSONS_WITH_HIV_AIDS',
        'HOPWAMedAssistedLivingFac' => 'NO',
        'continuumProject' => 'NO',
      },
    },
    CLIENT: {
      values: {
        'dob' => '2000-03-29T05:00:00.000Z',
        'dob-dq' => 'FULL_DOB_REPORTED',
        'ssn' => 'XXXXX1234',
        'ssn-dq' => 'APPROXIMATE_OR_PARTIAL_SSN_REPORTED',
        'race' => ['WHITE', 'ASIAN'],
        'gender' => ['WOMAN', 'TRANSGENDER'],
        'pronouns' => ['she/her'],
        'veteran-status' => 'CLIENT_PREFERS_NOT_TO_ANSWER',
        'image_blob_id' => nil,
      },
      hud_values: {
        "names": [
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
    },
    FUNDER: {
      values: {
        'project-start' => '2010-11-01T04:00:00.000Z',
        'funder' => 'HUD_COC_TRANSITIONAL_HOUSING',
        'grant-id' => 'ABCDEF',
        'start' => '2022-12-01T05:00:00.000Z',
        'end' => '2023-03-24T04:00:00.000Z',
      },
      hud_values: {
        'funder' => 'HUD_COC_TRANSITIONAL_HOUSING',
        'otherFunder' => nil,
        'grantId' => 'ABCDEF',
        'startDate' => '2022-12-01',
        'endDate' => '2023-03-24',
      },
    },
    PROJECT_COC: {
      values: {
        'coc' => 'MA-504',
        'geocode' => '250354',
        'geotype' => 'SUBURBAN',
        'address1' => '1 State Street',
        'address2' => '',
        'city' => 'Brockton',
        'state' => 'MA',
        'zip' => '12345',
      },
      hud_values: {
        'cocCode' => 'MA-504',
        'geocode' => '250354',
        'geographyType' => 'SUBURBAN',
        'address1' => '1 State Street',
        'address2' => nil,
        'city' => 'Brockton',
        'state' => 'MA',
        'zip' => '12345',
      },
    },
    INVENTORY: {
      values: {
        'project-start' => '2023-01-13T05:00:00.000Z',
        'project-end' => '2023-01-28T05:00:00.000Z',
        'coc' => 'MA-504',
        'hhtype' => 'HOUSEHOLDS_WITH_AT_LEAST_ONE_ADULT_AND_ONE_CHILD',
        'es-availability' => 'SEASONAL',
        'es-bed-type' => 'OTHER',
        '2.07.1' => '2023-01-23T05:00:00.000Z',
        '2.07.2' => '2023-01-28T05:00:00.000Z',
      },
      hud_values: {
        'cocCode' => 'CO-500',
        'householdType' => 'HOUSEHOLDS_WITH_AT_LEAST_ONE_ADULT_AND_ONE_CHILD',
        'availability' => 'SEASONAL',
        'esBedType' => 'OTHER',
        'inventoryStartDate' => '2023-01-23',
        'inventoryEndDate' => '2023-01-28',
        'unitInventory' => 0,
        'bedInventory' => 0,
      },
    },
    ORGANIZATION: {
      values: {
        'name' => 'Test org',
        'description' => 'description',
        'contact' => nil,
        'victimServiceProvider' => 'NO',
      },
      hud_values: {
        'organizationName' => 'Test org',
        'description' => 'description',
        'contactInformation' => nil,
        'victimServiceProvider' => 'NO',
      },
    },
    SERVICE: {
      values: {
        'movingOnOtherType' => 'something',
        'dateProvided' => '2023-03-15',
      },
      hud_values: {
        'otherTypeProvided' => '_HIDDEN',
        'movingOnOtherType' => 'something',
        'subTypeProvided' => '_HIDDEN',
        'faAmount' => '_HIDDEN',
        'referralOutcome' => '_HIDDEN',
        'dateProvided' => '2023-03-15',
      },
    },
    FILE: {
      values: {
        'file-confidential' => false,
        'file-enrollment' => nil,
      },
      hud_values: {
        'confidential' => false,
        'enrollmentId' => nil,
      },
    },
    ENROLLMENT: {
      values: {
        'entry-date' => Date.yesterday.strftime('%Y-%m-%d'),
        'relationship-to-hoh' => 'SELF_HEAD_OF_HOUSEHOLD',
      },
      hud_values: {
        'entryDate' => Date.yesterday.strftime('%Y-%m-%d'),
        'relationshipToHoH' => 'SELF_HEAD_OF_HOUSEHOLD',
      },
    },
    NEW_CLIENT_ENROLLMENT: {
      values: {
        'dob' => '2000-03-29T05:00:00.000Z',
        'dob-dq' => 'FULL_DOB_REPORTED',
        'ssn' => 'XXXXX1234',
        'ssn-dq' => 'APPROXIMATE_OR_PARTIAL_SSN_REPORTED',
        'race' => ['WHITE', 'ASIAN'],
        'gender' => ['WOMAN', 'TRANSGENDER'],
        'veteran-status' => 'CLIENT_PREFERS_NOT_TO_ANSWER',
        'entry-date' => '2023-09-07',
        'relationship-to-hoh' => 'SELF_HEAD_OF_HOUSEHOLD',
      },
      hud_values: {
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
    },
    CURRENT_LIVING_SITUATION: {
      values: {
        '4.12.1' => '2023-07-27T05:00:00.000Z',
        '4.12.2' => 'FOSTER_CARE_HOME_OR_FOSTER_CARE_GROUP_HOME',
        '4.12.B' => 'YES',
        '4.12.C' => 'NO',
        '4.12.D' => 'CLIENT_PREFERS_NOT_TO_ANSWER',
        '4.12.E' => 'CLIENT_DOESN_T_KNOW',
        '4.12.F' => 'YES',
        '4.12.4' => 'test',
      },
      hud_values: {
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
    },
    CE_ASSESSMENT: {
      values: {
        '4.19.1' => '2023-08-15',
        '4.19.2' => 'test',
        '4.19.3' => 'PHONE',
        '4.19.4' => 'CRISIS_NEEDS_ASSESSMENT',
        '4.19.7' => 'PLACED_ON_PRIORITIZATION_LIST',
      },
      hud_values: {
        'assessmentDate' => '2023-08-15',
        'assessmentLocation' => 'test',
        'assessmentType' => 'PHONE',
        'assessmentLevel' => 'CRISIS_NEEDS_ASSESSMENT',
        'prioritizationStatus' => 'PLACED_ON_PRIORITIZATION_LIST',
      },
    },
    CE_EVENT: {
      values: {
        '4.20.1' => '2023-08-12',
        '4.20.2' => 'REFERRAL_TO_JOINT_TH_RRH_PROJECT_UNIT_RESOURCE_OPENING',
        '4.20.C' => 'test',
        '4.20.D' => 'SUCCESSFUL_REFERRAL_CLIENT_ACCEPTED',
        '4.20.E' => '2023-08-16',
      },
      hud_values: {
        'eventDate' => '2023-08-12',
        'event' => 'REFERRAL_TO_JOINT_TH_RRH_PROJECT_UNIT_RESOURCE_OPENING',
        'probSolDivRrResult' => '_HIDDEN',
        'referralCaseManageAfter' => '_HIDDEN',
        'locationCrisisOrPhHousing' => 'test',
        'referralResult' => 'SUCCESSFUL_REFERRAL_CLIENT_ACCEPTED',
        'resultDate' => '2023-08-16',
      },
    },
    CASE_NOTE: {
      values: {
        content: 'test',
      },
      hud_values: {
        content: 'test',
      },
    },
    HMIS_PARTICIPATION: {
      values: {
        "2.08.1": 'HMIS_PARTICIPATING',
        "2.08.2": '2020-07-19',
        "2.08.3": nil,
      },
      hud_values: {
        "hmisParticipationType": 'HMIS_PARTICIPATING',
        "hmisParticipationStatusStartDate": '2020-07-19',
        "hmisParticipationStatusEndDate": nil,
      },
    },
    CE_PARTICIPATION: {
      values: {
        "2.09.1": 'YES',
        "2.09.A.prevention": 'YES',
        "2.09.A.crisis": 'YES',
        "2.09.A.housing": 'YES',
        "2.09.A.services": 'YES',
        "2.09.2": 'YES',
        "2.09.3": '2020-07-01',
        "2.09.4": nil,
      },
      hud_values: {
        "accessPoint": 'YES',
        "preventionAssessment": 'YES',
        "crisisAssessment": 'YES',
        "housingAssessment": 'YES',
        "directServices": 'YES',
        "receivesReferrals": 'YES',
        "ceParticipationStatusStartDate": '2020-07-01',
        "ceParticipationStatusEndDate": nil,
      },
    },
  }.freeze
end
