###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Code initially written for and funded by Delaware Health and Social Services.
# Used and modified with permission.
#
# A variable name may be repeated across datasets and years, but we
# store a record for each combination of year/dataset/variable in
# case they have different meanings or testing methodologies. It
# might not really matter, but this just seems safer

module GrdaWarehouse
  module UsCensusApi
    class CensusVariable < GrdaWarehouseBase

      VALID_NAME = /\A([_A-Z0-9](|::))+\Z/

      has_many :census_values, inverse_of: :census_variable

      validates :dataset, presence: true
      validates :name, presence: true
      validates :year, numericality: { only_integer: true, greater_than: 2000 }
      validates :year, presence: true
      validates :year, uniqueness: { scope: [:name, :dataset]}

      scope :with_internal_name, -> { where("internal_name is not null") }
      scope :for_dataset,        -> (d) { where(dataset: d) }
      scope :for_year,           -> (y) { where(year: y) }

      def the_group
        CensusGroup.where(dataset: self.dataset, year: self.year, name: self.census_group)
      end
    end
  end
end
