###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # Static registry of household composition fields exposed as household.* CE match expression keys
  # (e.g. household.size). HouseholdSelector decides which household is evaluated.
  class HouseholdFieldRegistry
    SIZE = HouseholdField.new(
      key: 'size',
      value_type: :numeric,
      multiple: false,
      label: 'Household Size',
      description: "Number of people currently enrolled in the client's household, including the client. " \
                   'If the client is in more than one household in the CE eligibility project group, the largest is used.',
    )

    YOUNGEST_MEMBER_AGE = HouseholdField.new(
      key: 'youngest_member_age',
      value_type: :numeric,
      multiple: false,
      label: 'Youngest Household Member Age',
      description: "Age in years of the youngest person currently enrolled in the client's household. " \
                   'Members without a date of birth are not counted.',
    )

    OLDEST_MEMBER_AGE = HouseholdField.new(
      key: 'oldest_member_age',
      value_type: :numeric,
      multiple: false,
      label: 'Oldest Household Member Age',
      description: "Age in years of the oldest person currently enrolled in the client's household. " \
                   'Members without a date of birth are not counted.',
    )

    ALL = [
      SIZE,
      YOUNGEST_MEMBER_AGE,
      OLDEST_MEMBER_AGE,
    ].freeze

    def self.[](key)
      by_key[key]
    end

    def self.by_key
      @by_key ||= ALL.index_by(&:key).freeze
    end
  end
end
