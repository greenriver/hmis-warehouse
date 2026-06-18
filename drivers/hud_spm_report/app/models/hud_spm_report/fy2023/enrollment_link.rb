###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport::Fy2023
  class EnrollmentLink < GrdaWarehouseBase
    self.table_name = 'hud_report_spm_enrollment_links'
    belongs_to :enrollment, class_name: 'HudSpmReport::Fy2023::SpmEnrollment'
    belongs_to :episode, optional: true
  end
end
