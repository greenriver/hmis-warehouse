###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientAccessControl::GrdaWarehouse::Hud
  module EnrollmentExtension
    extend ActiveSupport::Concern

    included do
      scope :visible_to, ->(user, client_ids: nil) do
        merge(GrdaWarehouse::Config.arbiter_class.new.enrollments_visible_to(user, client_ids: client_ids))
      end
    end
  end
end
