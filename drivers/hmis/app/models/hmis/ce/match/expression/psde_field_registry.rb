###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # Static registry of HUD table fields exposed as flat psde.* CE match expression keys
  # (e.g. psde.total_monthly_income). HUD table/column metadata lives on each PsdeField.
  class PsdeFieldRegistry
    TOTAL_MONTHLY_INCOME = PsdeField.new(
      key: 'total_monthly_income',
      table: 'IncomeBenefits',
      column: 'TotalMonthlyIncome',
      value_type: :numeric,
      label: 'Total Monthly Income',
      description: 'Latest total monthly income from HUD IncomeBenefits within the configured eligibility scope. ' \
                   'Selects the most recent row with a valid IncomeFromAnySource (skipping 8/9/99/nil).',
    )

    MENTAL_HEALTH_DISORDER = PsdeField.new(
      key: 'mental_health_disorder',
      table: 'Disabilities',
      column: 'DisabilityResponse',
      value_type: :logical,
      label: 'Mental Health Disorder',
      description: 'Latest response for HUD Mental Health Disorder (HUD Disabilities, DisabilityType 9) within the configured eligibility scope. ' \
                   'Selects the most recent row with a meaningful Yes or No value (skipping 8/9/99/nil).',
    )

    SUBSTANCE_USE_DISORDER = PsdeField.new(
      key: 'substance_use_disorder',
      table: 'Disabilities',
      column: 'DisabilityResponse',
      value_type: :logical,
      label: 'Substance Use Disorder',
      description: 'Latest response for HUD Substance Use Disorder (HUD Disabilities, DisabilityType 10) within the configured eligibility scope. ' \
                   'Selects the most recent row with a meaningful response (skipping 8/9/99/nil): true for Alcohol/Drug/Both (1/2/3), false for No (0).',
    )

    PHYSICAL_DISABILITY = PsdeField.new(
      key: 'physical_disability',
      table: 'Disabilities',
      column: 'DisabilityResponse',
      value_type: :logical,
      label: 'Physical Disability',
      description: 'Latest response for HUD Physical Disability (HUD Disabilities, DisabilityType 5) within the configured eligibility scope. ' \
                   'Selects the most recent row with a meaningful Yes or No value (skipping 8/9/99/nil).',
    )

    DEVELOPMENTAL_DISABILITY = PsdeField.new(
      key: 'developmental_disability',
      table: 'Disabilities',
      column: 'DisabilityResponse',
      value_type: :logical,
      label: 'Developmental Disability',
      description: 'Latest response for HUD Developmental Disability (HUD Disabilities, DisabilityType 6) within the configured eligibility scope. ' \
                   'Selects the most recent row with a meaningful Yes or No value (skipping 8/9/99/nil).',
    )

    CHRONIC_HEALTH_CONDITION = PsdeField.new(
      key: 'chronic_health_condition',
      table: 'Disabilities',
      column: 'DisabilityResponse',
      value_type: :logical,
      label: 'Chronic Health Condition',
      description: 'Latest response for HUD Chronic Health Condition (HUD Disabilities, DisabilityType 7) within the configured eligibility scope. ' \
                   'Selects the most recent row with a meaningful Yes or No value (skipping 8/9/99/nil).',
    )

    HIV_AIDS = PsdeField.new(
      key: 'hiv_aids',
      table: 'Disabilities',
      column: 'DisabilityResponse',
      value_type: :logical,
      label: 'HIV/AIDS',
      description: 'Latest response for HUD HIV/AIDS (HUD Disabilities, DisabilityType 8) within the configured eligibility scope. ' \
                   'Selects the most recent row with a meaningful Yes or No value (skipping 8/9/99/nil).',
    )

    DOMESTIC_VIOLENCE_SURVIVOR = PsdeField.new(
      key: 'domestic_violence_survivor',
      table: 'HealthAndDV',
      column: 'DomesticViolenceSurvivor',
      value_type: :logical,
      label: 'DV Survivor',
      description: 'Latest response for HUD Domestic Violence Survivor (HUD HealthAndDV) within the configured eligibility scope. ' \
                   'Selects the most recent row with a meaningful Yes or No value (skipping 8/9/99/nil).',
    )

    ALL = [
      TOTAL_MONTHLY_INCOME,
      MENTAL_HEALTH_DISORDER,
      SUBSTANCE_USE_DISORDER,
      PHYSICAL_DISABILITY,
      DEVELOPMENTAL_DISABILITY,
      CHRONIC_HEALTH_CONDITION,
      HIV_AIDS,
      DOMESTIC_VIOLENCE_SURVIVOR,
    ].freeze

    def self.[](key)
      by_key[key]
    end

    def self.by_key
      @by_key ||= ALL.index_by(&:key).freeze
    end
  end
end
