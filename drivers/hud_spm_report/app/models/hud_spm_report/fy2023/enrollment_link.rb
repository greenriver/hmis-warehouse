###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Fy2023
  class EnrollmentLink < GrdaWarehouseBase
    self.table_name = 'hud_report_spm_enrollment_links'
    belongs_to :enrollment, class_name: 'HudSpmReport::Fy2023::SpmEnrollment'
    belongs_to :episode, optional: true
  end
end
