###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Code initially written for and funded by Delaware Health and Social Services.
# Used and modified with permission.

module GrdaWarehouse
  module UsCensusApi
    class CensusValue < GrdaWarehouseBase
      belongs_to :census_variable, inverse_of: :census_values, optional: true
      belongs_to :location, optional: true, foreign_key: :full_geoid, primary_key: :full_geoid

      validates :full_geoid, uniqueness: { scope: [:census_variable_id] }
      validates :value, numericality: true

      delegate :internal_name, :year, :dataset, to: :census_variable
    end
  end
end
