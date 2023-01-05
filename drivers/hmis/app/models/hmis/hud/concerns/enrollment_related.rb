###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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

    # hide previous declaration of :editable_by, we'll use this one
    replace_scope :editable_by, ->(user) do
      joins(:enrollment).merge(Hmis::Hud::Enrollment.editable_by(user))
    end
  end
end
