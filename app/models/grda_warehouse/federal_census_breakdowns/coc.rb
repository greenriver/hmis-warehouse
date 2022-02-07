###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::FederalCensusBreakdowns
  class Coc < Base
    scope :for_date, ->(date) do
      # distinct on
      distinct_on(:coc_level, :geography, :group, :measure).
        where(arel_table[:accurate_on].lteq(date))
    end

    scope :coc_level, -> do
      where(geography_level: 'CoC')
    end

    scope :with_geography, ->(geography) do
      where(geography: geography)
    end

    scope :full_set, -> do
      where(race: :all, gender: :all, age_min: 0, age_max: 105)
    end

    scope :with_measure, ->(measure) do
      where(measure: measure)
    end
  end
end
