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
    VALUES_IN_WINDOW_SUFFIX = '_values_in_window'

    def self.latest_boolean_field(key:, label:, hud_description:)
      PsdeField.new(
        key: key,
        value_type: :logical,
        multiple: false,
        label: "#{label} (most recent)",
        description: "The client's most recent Yes or No response for #{hud_description}, within the eligibility scope. " \
                     'Refused, unknown, not collected (8/9/99) and blank answers are ignored.', \
      )
    end

    def self.values_in_window_boolean_field(key:, label:, hud_description:)
      PsdeField.new(
        key: "#{key}#{VALUES_IN_WINDOW_SUFFIX}",
        value_type: :logical,
        multiple: true,
        label: "#{label} (all values in window)",
        description: "All of this client's Yes or No responses for #{hud_description}, within the eligibility scope. " \
                     'Refused, unknown, not collected (8/9/99) and blank answers are ignored. ',
      )
    end

    TOTAL_MONTHLY_INCOME = PsdeField.new(
      key: 'total_monthly_income',
      value_type: :numeric,
      multiple: false,
      label: 'Total Monthly Income',
      description: "The client's most recent total monthly income from HUD Income and Benefits records " \
                   'within the eligibility scope. Refused, unknown, not collected (8/9/99) and blank answers are ignored.',
    )

    MENTAL_HEALTH_DISORDER = latest_boolean_field(
      key: 'mental_health_disorder',
      label: 'Mental Health Disorder',
      hud_description: 'HUD Mental Health Disorder (HUD Disabilities, DisabilityType 9)',
    )
    MENTAL_HEALTH_DISORDER_VALUES_IN_WINDOW = values_in_window_boolean_field(
      key: 'mental_health_disorder',
      label: 'Mental Health Disorder',
      hud_description: 'HUD Mental Health Disorder (HUD Disabilities, DisabilityType 9)',
    )

    SUBSTANCE_USE_DISORDER = latest_boolean_field(
      key: 'substance_use_disorder',
      label: 'Substance Use Disorder',
      hud_description: 'HUD Substance Use Disorder (HUD Disabilities, DisabilityType 10)',
    )
    SUBSTANCE_USE_DISORDER_VALUES_IN_WINDOW = values_in_window_boolean_field(
      key: 'substance_use_disorder',
      label: 'Substance Use Disorder',
      hud_description: 'HUD Substance Use Disorder (HUD Disabilities, DisabilityType 10)',
    )

    PHYSICAL_DISABILITY = latest_boolean_field(
      key: 'physical_disability',
      label: 'Physical Disability',
      hud_description: 'HUD Physical Disability (HUD Disabilities, DisabilityType 5)',
    )
    PHYSICAL_DISABILITY_VALUES_IN_WINDOW = values_in_window_boolean_field(
      key: 'physical_disability',
      label: 'Physical Disability',
      hud_description: 'HUD Physical Disability (HUD Disabilities, DisabilityType 5)',
    )

    DEVELOPMENTAL_DISABILITY = latest_boolean_field(
      key: 'developmental_disability',
      label: 'Developmental Disability',
      hud_description: 'HUD Developmental Disability (HUD Disabilities, DisabilityType 6)',
    )
    DEVELOPMENTAL_DISABILITY_VALUES_IN_WINDOW = values_in_window_boolean_field(
      key: 'developmental_disability',
      label: 'Developmental Disability',
      hud_description: 'HUD Developmental Disability (HUD Disabilities, DisabilityType 6)',
    )

    CHRONIC_HEALTH_CONDITION = latest_boolean_field(
      key: 'chronic_health_condition',
      label: 'Chronic Health Condition',
      hud_description: 'HUD Chronic Health Condition (HUD Disabilities, DisabilityType 7)',
    )
    CHRONIC_HEALTH_CONDITION_VALUES_IN_WINDOW = values_in_window_boolean_field(
      key: 'chronic_health_condition',
      label: 'Chronic Health Condition',
      hud_description: 'HUD Chronic Health Condition (HUD Disabilities, DisabilityType 7)',
    )

    HIV_AIDS = latest_boolean_field(
      key: 'hiv_aids',
      label: 'HIV/AIDS',
      hud_description: 'HUD HIV/AIDS (HUD Disabilities, DisabilityType 8)',
    )
    HIV_AIDS_VALUES_IN_WINDOW = values_in_window_boolean_field(
      key: 'hiv_aids',
      label: 'HIV/AIDS',
      hud_description: 'HUD HIV/AIDS (HUD Disabilities, DisabilityType 8)',
    )

    DOMESTIC_VIOLENCE_SURVIVOR = latest_boolean_field(
      key: 'domestic_violence_survivor',
      label: 'DV Survivor',
      hud_description: 'HUD Domestic Violence Survivor (HUD HealthAndDV)',
    )
    DOMESTIC_VIOLENCE_SURVIVOR_VALUES_IN_WINDOW = values_in_window_boolean_field(
      key: 'domestic_violence_survivor',
      label: 'DV Survivor',
      hud_description: 'HUD Domestic Violence Survivor (HUD HealthAndDV)',
    )

    ALL = [
      TOTAL_MONTHLY_INCOME,
      MENTAL_HEALTH_DISORDER,
      MENTAL_HEALTH_DISORDER_VALUES_IN_WINDOW,
      SUBSTANCE_USE_DISORDER,
      SUBSTANCE_USE_DISORDER_VALUES_IN_WINDOW,
      PHYSICAL_DISABILITY,
      PHYSICAL_DISABILITY_VALUES_IN_WINDOW,
      DEVELOPMENTAL_DISABILITY,
      DEVELOPMENTAL_DISABILITY_VALUES_IN_WINDOW,
      CHRONIC_HEALTH_CONDITION,
      CHRONIC_HEALTH_CONDITION_VALUES_IN_WINDOW,
      HIV_AIDS,
      HIV_AIDS_VALUES_IN_WINDOW,
      DOMESTIC_VIOLENCE_SURVIVOR,
      DOMESTIC_VIOLENCE_SURVIVOR_VALUES_IN_WINDOW,
    ].freeze

    def self.[](key)
      by_key[key]
    end

    def self.by_key
      @by_key ||= ALL.index_by(&:key).freeze
    end
  end
end
