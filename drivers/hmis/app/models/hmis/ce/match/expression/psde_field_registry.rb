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

    ALL = [
      TOTAL_MONTHLY_INCOME,
    ].freeze

    def self.[](key)
      by_key[key]
    end

    def self.by_key
      @by_key ||= ALL.index_by(&:key).freeze
    end
  end
end
