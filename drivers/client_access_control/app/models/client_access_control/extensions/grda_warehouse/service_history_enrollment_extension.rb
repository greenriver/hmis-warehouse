###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ClientAccessControl::GrdaWarehouse
  module ServiceHistoryEnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :visible_to, ->(user) do
        joins(:enrollment).merge(GrdaWarehouse::Hud::Enrollment.visible_to(user))
      end
    end
  end
end
