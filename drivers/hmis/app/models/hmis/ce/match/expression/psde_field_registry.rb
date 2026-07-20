###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # Static registry of HUD table fields exposed as flat psde.* CE match expression keys
  # (e.g. psde.monthly_total_income). HUD table/column metadata lives on each PsdeField.
  class PsdeFieldRegistry
    INVALID_INCOME_FROM_ANY_SOURCE = [8, 9, 99].freeze

    MONTHLY_TOTAL_INCOME = PsdeField.new(
      key: 'monthly_total_income',
      table: 'IncomeBenefits',
      column: 'TotalMonthlyIncome',
      value_type: :numeric,
      label: 'Monthly Total Income',
      description: 'Latest monthly total income from HUD IncomeBenefits within the configured eligibility scope. ' \
                   'Selects the most recent row with a valid IncomeFromAnySource (skipping 8/9/99/nil).',
    )

    ALL = [
      MONTHLY_TOTAL_INCOME,
    ].freeze

    def self.[](key)
      by_key[key]
    end

    def self.by_key
      @by_key ||= ALL.index_by(&:key).freeze
    end
  end
end
