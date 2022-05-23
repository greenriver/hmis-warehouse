###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module LongitudinalSpm
  class Spm < GrdaWarehouseBase
    self.table_name = :longitudinal_spm_spms
    acts_as_paranoid

    belongs_to :report
    belongs_to :hud_spm, class_name: 'HudReports::ReportInstance', foreign_key: :spm_id
  end
end
