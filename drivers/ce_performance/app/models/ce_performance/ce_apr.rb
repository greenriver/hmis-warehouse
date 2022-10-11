###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CePerformance
  class CeApr < GrdaWarehouseBase
    acts_as_paranoid

    belongs_to :report
    belongs_to :hud_ce_apr, class_name: 'HudReports::ReportInstance', foreign_key: :ce_apr_id
  end
end
