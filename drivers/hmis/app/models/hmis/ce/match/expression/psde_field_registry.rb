###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # Static registry of HUD table fields exposed as flat psde.* CE match expression keys
  # (e.g. psde.total_monthly_income).
  class PsdeFieldRegistry
    ALL_ENROLLMENT_SUFFIX = '_all_enrollment_values'

    def self.latest_boolean_field(key:, label:, hud_description:)
      PsdeField.new(
        key: key,
        value_type: :logical,
        multiple: false,
        label: "#{label} (latest)",
        description: "Latest response for #{hud_description} within the configured eligibility scope. " \
                     'Selects the most recent row with a meaningful value (skipping 8/9/99/nil).',
      )
    end

    def self.all_enrollment_boolean_field(key:, label:, hud_description:)
      PsdeField.new(
        key: "#{key}#{ALL_ENROLLMENT_SUFFIX}",
        value_type: :logical,
        multiple: true,
        label: "#{label} (all enrollment values)",
        description: "Array of per-enrollment responses for #{hud_description} within the configured eligibility scope. " \
                     "For each in-scope enrollment, takes that enrollment's most recent meaningful value (skipping 8/9/99/nil). " \
                     'Use with INCLUDES(..., TRUE) to match clients who were ever Yes in the window.',
      )
    end

    TOTAL_MONTHLY_INCOME = PsdeField.new(
      key: 'total_monthly_income',
      value_type: :numeric,
      multiple: false,
      label: 'Total Monthly Income',
      description: 'Latest total monthly income from HUD IncomeBenefits within the configured eligibility scope. ' \
                   'Selects the most recent row with a valid IncomeFromAnySource (skipping 8/9/99/nil).',
    )

    MENTAL_HEALTH_DISORDER = latest_boolean_field(
      key: 'mental_health_disorder',
      label: 'Mental Health Disorder',
      hud_description: 'HUD Mental Health Disorder (HUD Disabilities, DisabilityType 9)',
    )
    MENTAL_HEALTH_DISORDER_ALL_ENROLLMENT_VALUES = all_enrollment_boolean_field(
      key: 'mental_health_disorder',
      label: 'Mental Health Disorder',
      hud_description: 'HUD Mental Health Disorder (HUD Disabilities, DisabilityType 9)',
    )

    SUBSTANCE_USE_DISORDER = latest_boolean_field(
      key: 'substance_use_disorder',
      label: 'Substance Use Disorder',
      hud_description: 'HUD Substance Use Disorder (HUD Disabilities, DisabilityType 10)',
    )
    SUBSTANCE_USE_DISORDER_ALL_ENROLLMENT_VALUES = all_enrollment_boolean_field(
      key: 'substance_use_disorder',
      label: 'Substance Use Disorder',
      hud_description: 'HUD Substance Use Disorder (HUD Disabilities, DisabilityType 10)',
    )

    PHYSICAL_DISABILITY = latest_boolean_field(
      key: 'physical_disability',
      label: 'Physical Disability',
      hud_description: 'HUD Physical Disability (HUD Disabilities, DisabilityType 5)',
    )
    PHYSICAL_DISABILITY_ALL_ENROLLMENT_VALUES = all_enrollment_boolean_field(
      key: 'physical_disability',
      label: 'Physical Disability',
      hud_description: 'HUD Physical Disability (HUD Disabilities, DisabilityType 5)',
    )

    DEVELOPMENTAL_DISABILITY = latest_boolean_field(
      key: 'developmental_disability',
      label: 'Developmental Disability',
      hud_description: 'HUD Developmental Disability (HUD Disabilities, DisabilityType 6)',
    )
    DEVELOPMENTAL_DISABILITY_ALL_ENROLLMENT_VALUES = all_enrollment_boolean_field(
      key: 'developmental_disability',
      label: 'Developmental Disability',
      hud_description: 'HUD Developmental Disability (HUD Disabilities, DisabilityType 6)',
    )

    CHRONIC_HEALTH_CONDITION = latest_boolean_field(
      key: 'chronic_health_condition',
      label: 'Chronic Health Condition',
      hud_description: 'HUD Chronic Health Condition (HUD Disabilities, DisabilityType 7)',
    )
    CHRONIC_HEALTH_CONDITION_ALL_ENROLLMENT_VALUES = all_enrollment_boolean_field(
      key: 'chronic_health_condition',
      label: 'Chronic Health Condition',
      hud_description: 'HUD Chronic Health Condition (HUD Disabilities, DisabilityType 7)',
    )

    HIV_AIDS = latest_boolean_field(
      key: 'hiv_aids',
      label: 'HIV/AIDS',
      hud_description: 'HUD HIV/AIDS (HUD Disabilities, DisabilityType 8)',
    )
    HIV_AIDS_ALL_ENROLLMENT_VALUES = all_enrollment_boolean_field(
      key: 'hiv_aids',
      label: 'HIV/AIDS',
      hud_description: 'HUD HIV/AIDS (HUD Disabilities, DisabilityType 8)',
    )

    DOMESTIC_VIOLENCE_SURVIVOR = latest_boolean_field(
      key: 'domestic_violence_survivor',
      label: 'DV Survivor',
      hud_description: 'HUD Domestic Violence Survivor (HUD HealthAndDV)',
    )
    DOMESTIC_VIOLENCE_SURVIVOR_ALL_ENROLLMENT_VALUES = all_enrollment_boolean_field(
      key: 'domestic_violence_survivor',
      label: 'DV Survivor',
      hud_description: 'HUD Domestic Violence Survivor (HUD HealthAndDV)',
    )

    ALL = [
      TOTAL_MONTHLY_INCOME,
      MENTAL_HEALTH_DISORDER,
      MENTAL_HEALTH_DISORDER_ALL_ENROLLMENT_VALUES,
      SUBSTANCE_USE_DISORDER,
      SUBSTANCE_USE_DISORDER_ALL_ENROLLMENT_VALUES,
      PHYSICAL_DISABILITY,
      PHYSICAL_DISABILITY_ALL_ENROLLMENT_VALUES,
      DEVELOPMENTAL_DISABILITY,
      DEVELOPMENTAL_DISABILITY_ALL_ENROLLMENT_VALUES,
      CHRONIC_HEALTH_CONDITION,
      CHRONIC_HEALTH_CONDITION_ALL_ENROLLMENT_VALUES,
      HIV_AIDS,
      HIV_AIDS_ALL_ENROLLMENT_VALUES,
      DOMESTIC_VIOLENCE_SURVIVOR,
      DOMESTIC_VIOLENCE_SURVIVOR_ALL_ENROLLMENT_VALUES,
    ].freeze

    def self.[](key)
      by_key[key]
    end

    def self.by_key
      @by_key ||= ALL.index_by(&:key).freeze
    end
  end
end
