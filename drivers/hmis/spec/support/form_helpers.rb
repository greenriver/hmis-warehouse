###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
        '2.02.6' => 'ES',
        '2.02.C' => 'NIGHT_BY_NIGHT',
        '2.02.D' => 'SITE_BASED_SINGLE_SITE',
        '2.02.8' => 'PERSONS_WITH_HIV_AIDS',
        '2.02.9' => 'NO',
        '2.02.5' => nil,
        '2.02.7' => nil,
      },
      hud_values: {
        'projectName' => 'Test Project',
        'description' => nil,
        'contactInformation' => nil,
        'operatingStartDate' => '2023-01-13',
        'operatingEndDate' => '2023-01-28',
        'projectType' => 'ES',
        'trackingMethod' => 'NIGHT_BY_NIGHT',
        'residentialAffiliation' => nil,
        'housingType' => 'SITE_BASED_SINGLE_SITE',
        'targetPopulation' => 'PERSONS_WITH_HIV_AIDS',
        'HOPWAMedAssistedLivingFac' => 'NO',
        'continuumProject' => 'NO',
        'HMISParticipatingProject' => 'YES',
      },
    },
    CLIENT: {
      values: {
        'dob' => '2000-03-29T05:00:00.000Z',
        'dob-dq' => 'FULL_DOB_REPORTED',
        'ssn' => 'XXXXX1234',
        'ssn-dq' => 'APPROXIMATE_OR_PARTIAL_SSN_REPORTED',
        'race' => ['WHITE', 'ASIAN'],
        'ethnicity' => 'HISPANIC_LATIN_A_O_X',
        'gender' => ['FEMALE', 'TRANSGENDER'],
        'pronouns' => ['she/her'],
        'veteran-status' => 'CLIENT_REFUSED',
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
        'ethnicity' => 'HISPANIC_LATIN_A_O_X',
        'gender' => [
          'FEMALE',
          'TRANSGENDER',
        ],
        'pronouns' => [
          'she/her',
        ],
        'veteranStatus' => 'CLIENT_REFUSED',
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
        'confidential' => false,
        'enrollmentId' => nil,
        'effectiveDate' => '2023-03-17',
        'expirationDate' => nil,
      },
      hud_values: {
        'confidential' => false,
        'enrollmentId' => nil,
        'effectiveDate' => '2023-03-17',
        'expirationDate' => nil,
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
  }.freeze
end
