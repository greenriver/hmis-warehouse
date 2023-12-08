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
      joins(:enrollment).merge(Hmis::Hud::Enrollment.viewable_by(user))
    end

    has_paper_trail(
      meta: {
        enrollment_id: ->(r) { r.enrollment&.id },
        client_id: ->(r) { r.enrollment&.client&.id },
        project_id: ->(r) { r.enrollment&.project&.id },
      },
    )
  end
end
