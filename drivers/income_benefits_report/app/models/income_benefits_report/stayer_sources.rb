###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  IncomeBenefitsReport::StayerSources
  extend ActiveSupport::Concern
  included do
    def stayer_income_sources_data
      {}.tap do |data|
        ::GrdaWarehouse::Hud::IncomeBenefit::SOURCES.each_key do |source|
          source_count = stayers_adults.joins(:later_income_record).where(IncomeBenefitsReport::Income.arel_table[source].eq(1)).count
          data[source] = {
            count: source_count,
            percent: calc_percent(source_count, stayers_adults_count),
            description: "Counts of adult stayers with income in the #{source} category out of all adult stayers.",
          }
        end
      end
    end

    def stayer_non_cash_sources_data
      {}.tap do |data|
        ::GrdaWarehouse::Hud::IncomeBenefit::NON_CASH_BENEFIT_TYPES.each do |source|
          source_count = stayers_adults.joins(:later_income_record).where(IncomeBenefitsReport::Income.arel_table[source].eq(1)).count
          data[source] = {
            count: source_count,
            percent: calc_percent(source_count, stayers_adults_count),
            description: "Counts of adult stayers with income in the #{source} category out of all adult stayers.",
          }
        end
      end
    end

    def stayer_insurance_sources_data
      {}.tap do |data|
        ::GrdaWarehouse::Hud::IncomeBenefit::INSURANCE_TYPES.each do |source|
          source_count = stayers_adults.joins(:later_income_record).where(IncomeBenefitsReport::Income.arel_table[source].eq(1)).count
          data[source] = {
            count: source_count,
            percent: calc_percent(source_count, stayers_adults_count),
            description: "Counts of adult stayers with income in the #{source} category out of all adult stayers.",
          }
        end
      end
    end
  end
end
