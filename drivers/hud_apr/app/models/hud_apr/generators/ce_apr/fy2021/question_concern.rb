###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2021::QuestionConcern
  extend ActiveSupport::Concern

  included do
    # By default, only include members with assessments
    def self.filter_universe_members(associations)
      associations.reject { |_, row| row[:ce_assessment_date].blank? }
    end

    private def clients_with_enrollments(batch)
      client_ids = batch.map(&:id)
      assessed_clients = enrollment_scope.
        joins(:project, enrollment: :assessments).
        merge(GrdaWarehouse::Hud::Project.coc_funded).
        where(client_id: client_ids).
        order(as_t[:AssessmentDate].asc).
        group_by(&:client_id).
        transform_values { |enrollments| enrollments.reject { |enrollment| nbn_with_no_service?(enrollment) } }.
        reject { |_, enrollments| enrollments.empty? }

      other_client_ids = client_ids - assessed_clients.keys
      household_ids = assessed_clients.values.map(&:last).map(&:household_id)

      other_household_members = enrollment_scope.
        joins(:project).
        merge(GrdaWarehouse::Hud::Project.coc_funded).
        where.not(household_id: nil).
        where(client_id: other_client_ids, household_id: household_ids).
        order(first_date_in_program: :asc).
        group_by(&:client_id).
        transform_values { |enrollments| enrollments.reject { |enrollment| nbn_with_no_service?(enrollment) } }.
        reject { |_, enrollments| enrollments.empty? }

      non_household_client_ids = other_client_ids - other_household_members.keys

      non_household_members = enrollment_scope.
        joins(:project).
        merge(GrdaWarehouse::Hud::Project.coc_funded).
        where(client_id: non_household_client_ids).
        order(first_date_in_program: :asc).
        group_by(&:client_id).
        transform_values { |enrollments| enrollments.reject { |enrollment| nbn_with_no_service?(enrollment) } }.
        reject { |_, enrollments| enrollments.empty? }

      assessed_clients.
        merge(other_household_members).
        merge(non_household_members)
    end

    # private def enrollment_scope_without_preloads
    #   scope = GrdaWarehouse::ServiceHistoryEnrollment.
    #     entry.
    #     open_between(start_date: @report.start_date, end_date: @report.end_date).
    #     joins(enrollment: :assessments).
    #     merge(GrdaWarehouse::Hud::Assessment.within_range(@report.start_date..@report.end_date))
    #   scope = scope.in_project(@report.project_ids) if @report.project_ids.present? # for consistency with client_scope
    #   scope
    # end

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
