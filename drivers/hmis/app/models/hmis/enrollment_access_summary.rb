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

    def self.apply_filter(user:, starts_on: nil, search_term: nil, project_ids: nil)
      scope = self
      if starts_on
        date_range = (starts_on...)
        log_scope = Hmis::ActivityLog.where(user_id: user.id).where(created_at: date_range)
        scope = scope.where(enrollment_id: log_scope.select_enrollment_ids)
      end
      if search_term.present?
        # unscope client to include deleted records in the join
        enrollment_ids = []
        enrollment_ids += Hmis::Hud::Enrollment.unscoped do
          Hmis::Hud::Client.with_deleted.
            matching_search_term(search_term).
            joins(:enrollments).
            limit(50).
            pluck(e_t[:id])
        end

        enrollment_ids << search_term.to_i if search_term =~ /\A\d+\z/
        scope = scope.where(enrollment_id: enrollment_ids.uniq)
      end
      if project_ids.present?
        enrollment_ids = []
        Hmis::Hud::Project.unscoped do
          enrollment_ids += Hmis::Hud::Enrollment.with_deleted.joins(:project).where(project: {id:project_ids}).pluck(e_t[:id]).compact
        end
        enrollment_ids += Hmis::Wip.enrollments.where(project_id: project_ids).pluck(:source_id)
        scope = scope.where(enrollment_id: enrollment_ids.uniq)
      end
      scope.where(user_id: user.id)
    end
  end
end
