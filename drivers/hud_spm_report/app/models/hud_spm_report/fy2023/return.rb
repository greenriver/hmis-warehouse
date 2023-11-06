###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HHudSpmReport::Fy2023
  class Return < GrdaWarehouse
    self.table_name = 'hud_report_spm_returns'

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :exit_enrollment, class_name: 'Enrollment'
    belongs_to :return_enrollment, class_name: 'Enrollment'
    belongs_to :service, class_name: 'GrdaWarehouse::Hud::Service'
  end
end
