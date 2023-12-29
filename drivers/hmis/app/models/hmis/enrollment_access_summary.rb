###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# backed by a db view
module Hmis
  class EnrollmentAccessSummary < ApplicationRecord
    self.table_name = 'hmis_user_enrollment_activity_log_summaries'
    self.primary_key = 'id'

    belongs_to :user, class_name: 'Hmis::User'
    belongs_to :enrollment, class_name: 'Hmis::Hud::Enrollment'

    def readonly?
      true
    end

    def self.apply_filter(user:, starts_on: nil, search_term: nil)
      scope = self
      if starts_on
        date_range = (starts_on...)
        log_scope = Hmis::ActivityLog.where(user_id: user.id).
          where(created_at: date_range).
          joins('JOIN hmis_activity_logs_enrollments ON hmis_activity_logs_enrollments.activity_log_id = hmis_activity_logs.id')
        scope = scope.where(enrollment_id: log_scope.select(:enrollment_id))
      end
      if search_term.present?
        enrollment_ids = Hmis::Hud::Client.with_deleted.
          matching_search_term(search_term).
          joins(
            c_t.create_join(
              e_t,
              c_t.create_on(
                # joins to enrollments; intentionally includes deleted records
                [e_t[:PersonalID].eq(c_t[:PersonalID]), e_t[:data_source_id].eq(c_t[:data_source_id])].inject(&:and),
              ),
            ),
          ).
          limit(50).
          pluck(e_t[:id])
        enrollment_ids << search_term.to_i if search_term =~ /\A\d+\z/
        scope = scope.where(enrollment_id: enrollment_ids)
      end
      scope.where(user_id: user.id)
    end
  end
end
