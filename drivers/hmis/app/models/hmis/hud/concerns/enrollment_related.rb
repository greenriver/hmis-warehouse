###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Concerns::EnrollmentRelated
  extend ActiveSupport::Concern

  included do
    # hide previous declaration of :viewable_by, we'll use this one
    replace_scope :viewable_by, ->(user) do
     # permissions = [:can_view_enrollment_details, :can_view_project]
     # return none unless user.permissions?(*permissions)

     # project_ids = Hmis::Hud::Project.with_access(user, *permissions, mode: 'all').pluck(:id, :ProjectID)
     #
     # viewable_wip = wip_t[:project_id].in(project_ids.map(&:first))
     # viewable_enrollment = e_t[:ProjectID].in(project_ids.map(&:second))

     joins(:enrollment).merge(Hmis::Hud::Enrollment.viewable_by(user))
     #joins(:enrollment)
     #   where(
     #   Hmis::Hud::Enrollment.viewable_by(user)
     # )
    end
  end
end
