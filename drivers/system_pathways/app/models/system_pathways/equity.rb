###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
require 'memery'

module SystemPathways
  class Equity
    include ArelHelper
    include Memery
    include SystemPathways::ChartBase
    include SystemPathways::Equity::Race
    # include SystemPathways::Equity::Ethnicity
    # include SystemPathways::Equity::RaceAndEthnicity
    include SystemPathways::Equity::Veteran
    include SystemPathways::Equity::Chronic
    include SystemPathways::Equity::InvolvesCe
    include SystemPathways::Equity::DisablingCondition

    def known_categories
      [
        ['Race', 'race'],
        ['Ethnicity', 'ethnicity'],
        ['Race and Ethnicity', 'race_and_ethnicity'],
        ['Veteran Status', 'veteran_status'],
        ['Disabling Condition', 'disabling_condition'],
        ['Household Chronic at Entry', 'chronic_at_entry'],
        ['Participated in CE', 'involves_ce'],
      ]
    end

    def chart_data(chart)
      data = case chart.to_s
      when 'race'
        race_chart_data
      when 'ethnicity'
        ethnicity_chart_data
      when 'race_and_ethnicity'
        race_and_ethnicity_chart_data
      when 'veteran_status'
        veteran_chart_data
      when 'disabling_condition'
        disabling_condition_chart_data
      when 'chronic_at_entry'
        chronic_at_entry_chart_data
      when 'involves_ce'
        involves_ce_chart_data
      else
        {}
      end

      data
    end
  end
end
