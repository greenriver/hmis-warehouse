###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientAccessControl::GrdaWarehouse::Hud
  module EnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :visible_to, ->(user) do
        GrdaWarehouse::Config.arbiter_class.new.enrollments_visible_to(user)
      end
    end
  end
end
