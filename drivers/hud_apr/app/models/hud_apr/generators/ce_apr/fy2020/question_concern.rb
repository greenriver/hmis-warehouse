###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2020::QuestionConcern
  extend ActiveSupport::Concern

  included do
    private def clients_with_enrollments(batch)
      enrollment_scope.
        where(client_id: batch.map(&:id)).
        order(as_t[:AssessmentDate].asc).
        group_by(&:client_id).
        reject { |_, enrollments| nbn_with_no_service?(enrollments.last) }
    end

    private def enrollment_scope_without_preloads
      scope = GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        open_between(start_date: @report.start_date, end_date: @report.end_date).
        joins(enrollment: :assessments).
        merge(GrdaWarehouse::Hud::Assessment.within_range(@report.start_date..@report.end_date))
      scope = scope.in_project(@report.project_ids) if @report.project_ids.present? # for consistency with client_scope
      scope
    end

    # Only include ages for clients who were present on the assessment date
    private def ages_for(household_id, date)
      return [] unless households[household_id]

      households[household_id].reject do |client|
        client[:entry_date] > date || client[:exit_date].present? && client[:exit_date] < date
      end.map do |client|
        GrdaWarehouse::Hud::Client.age(date: date, dob: client[:dob])
      end
    end

    # Only include clients who were present on the assessment date
    private def household_member_data(enrollment, date)
      # return nil unless enrollment[:head_of_household]

      active_members = households[enrollment.household_id] || []
      active_members.reject do |client|
        client[:entry_date] > date || client[:exit_date].present? && client[:exit_date] < date
      end
    end
  end
end
