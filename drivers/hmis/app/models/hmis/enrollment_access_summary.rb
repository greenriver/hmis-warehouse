###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# backed by a db view
module Hmis
  class EnrollmentAccessSummary < ApplicationRecord
    self.table_name = 'hmis_user_client_activity_log_summaries'
    self.primary_key = 'id'

    belongs_to :user, class_name: 'Hmis::User'
    belongs_to :client, class_name: 'Hmis::Hud::Enrollment'

    def readonly?
      true
    end
  end
end
