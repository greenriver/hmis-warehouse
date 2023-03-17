# frozen_string_literal: true

module FormHelpers
  def build_minimum_values(definition, assessment_date, values: {}, hud_values: {})
    item = definition.assessment_date_item
    field_name = item.field_name
    field_name = 'Exit.exitDate' if field_name == 'exitDate'
    field_name = 'Enrollment.entryDate' if field_name == 'entryDate'
    {
      values: { item.link_id => assessment_date, **values.stringify_keys },
      hud_values: { field_name => assessment_date, **hud_values.stringify_keys },
    }
  end

  def custom_form_attributes(role, assessment_date)
    definition = Hmis::Form::Definition.find_by(role: role)
    raise "No definition for role #{role}" unless definition.present?

    {
      definition: definition,
      **build_minimum_values(definition, assessment_date),
    }
  end

  def find_required_item(definition)
    definition.link_id_item_hash.find { |_link_id, item| item.required && item.field_name.present? }&.last
  end

  def completed_form_values_for_role(role)
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
        '2.02.6' => {
          'code' => 'ES',
          'label' => 'Emergency Shelter',
        },
        '2.02.C' => {
          'code' => 'NIGHT_BY_NIGHT',
          'label' => 'Night-by-Night',
        },
        '2.02.D' => {
          'code' => 'SITE_BASED_SINGLE_SITE',
          'label' => 'Site-based - single site',
        },
        '2.02.8' => {
          'code' => 'PERSONS_WITH_HIV_AIDS',
          'label' => 'Persons with HIV/AIDS',
        },
        '2.02.9' => {
          'code' => 'NO',
          'label' => 'No',
        },
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
        'first-name' => 'First',
        'middle-name' => 'Middle',
        'last-name' => 'Last',
        'name-suffix' => 'Sf',
        'preferred-name' => 'Pref',
        'name-dq' => {
          'code' => 'FULL_NAME_REPORTED',
          'label' => 'Full name',
        },
        'dob' => '2000-03-29T05:00:00.000Z',
        'dob-dq' => {
          'code' => 'FULL_DOB_REPORTED',
          'label' => 'Full DOB',
        },
        'ssn' => 'XXXXX1234',
        'ssn-dq' => {
          'code' => 'APPROXIMATE_OR_PARTIAL_SSN_REPORTED',
          'label' => 'Partial SSN',
        },
        'race' => [
          {
            'code' => 'WHITE',
            'label' => 'White',
          },
          {
            'code' => 'ASIAN',
            'label' => 'Asian or Asian American',
          },
        ],
        'ethnicity' => {
          'code' => 'HISPANIC_LATIN_A_O_X',
          'label' => 'Hispanic/Latin(a)(o)(x)',
        },
        'gender' => [
          {
            'code' => 'FEMALE',
            'label' => 'Female',
          },
          {
            'code' => 'TRANSGENDER',
            'label' => 'Transgender',
          },
        ],
        'pronouns' => [
          {
            'code' => 'she/her',
          },
        ],
        'veteran-status' => {
          'code' => 'CLIENT_REFUSED',
          'label' => 'Client refused',
        },
        'image_blob_id' => nil,
      },
      hud_values: {
        'firstName' => 'First',
        'middleName' => 'Middle',
        'lastName' => 'Last',
        'nameSuffix' => 'Sf',
        'preferredName' => 'Pref',
        'nameDataQuality' => 'FULL_NAME_REPORTED',
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
        'funder' => {
          'code' => 'HUD_COC_TRANSITIONAL_HOUSING',
          'label' => 'HUD: CoC - Transitional Housing',
        },
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
        'coc' => {
          '__typename' => 'PickListOption',
          'code' => 'MA-504',
          'label' => 'MA-504 - Springfield/Hampden County CoC',
          'secondaryLabel' => nil,
          'groupLabel' => nil,
          'groupCode' => nil,
          'initialSelected' => false,
        },
        'geocode' => {
          '__typename' => 'PickListOption',
          'code' => '250354',
          'label' => '250354 - Brockton',
          'secondaryLabel' => nil,
          'groupLabel' => nil,
          'groupCode' => nil,
          'initialSelected' => nil,
        },
        'geotype' => {
          'code' => 'SUBURBAN',
          'label' => 'Suburban',
        },
        'address1' => '1 State Street',
        'address2' => '',
        'city' => 'Brockton',
        'state' => {
          '__typename' => 'PickListOption',
          'code' => 'MA',
          'label' => nil,
          'secondaryLabel' => nil,
          'groupLabel' => nil,
          'groupCode' => nil,
          'initialSelected' => true,
        },
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
        'coc' => {
          '__typename' => 'PickListOption',
          'code' => 'MA-504',
          'label' => 'MA-504 - Springfield/Hampden County CoC',
          'secondaryLabel' => nil,
          'groupLabel' => nil,
          'groupCode' => nil,
          'initialSelected' => true,
        },
        'hhtype' => {
          'code' => 'HOUSEHOLDS_WITH_AT_LEAST_ONE_ADULT_AND_ONE_CHILD',
          'label' => 'Households with at least one adult and one child',
        },
        'es-availability' => {
          'code' => 'SEASONAL',
          'label' => 'Seasonal',
        },
        'es-bed-type' => {
          'code' => 'OTHER',
          'label' => 'Other',
        },
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
        'victimServiceProvider' => { 'code' => 'NO' },
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
        'typeProvided' => 'MOVING_ON_ASSISTANCE__OTHER',
        'movingOnOtherType' => 'something',
        'dateProvided' => '2023-03-15',
      },
      hud_values: {
        'typeProvided' => 'MOVING_ON_ASSISTANCE__OTHER',
        'otherTypeProvided' => '_HIDDEN',
        'movingOnOtherType' => 'something',
        'subTypeProvided' => '_HIDDEN',
        'FAAmount' => '_HIDDEN',
        'referralOutcome' => '_HIDDEN',
        'dateProvided' => '2023-03-15',
      },
    },
  }.freeze
end
