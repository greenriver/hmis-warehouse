###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# for HUD entities that want to relate to a project through enrollments including WIP
module Hmis::Hud::Concerns::ClientProjectEnrollmentRelated
  extend ActiveSupport::Concern

  included do
    has_one :client_project, **hmis_relation(:EnrollmentID)
    has_one :project, through: :client_project

    # hide previous declaration of :viewable_by, we'll use this one
    replace_scope :viewable_by, ->(user) do
      joins(:enrollment).merge(Hmis::Hud::Enrollment.viewable_by(user))
    end
  end
end
