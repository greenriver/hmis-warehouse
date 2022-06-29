###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module LongitudinalSpm
  class Result < GrdaWarehouseBase
    self.table_name = :longitudinal_spm_results
    acts_as_paranoid

    belongs_to :report
    belongs_to :spm
  end
end
