###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module WarehouseReports
  class RunEnrolledDisabledJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(params)
      report = GrdaWarehouse::WarehouseReports::EnrolledDisabledReport.new
      report.started_at = DateTime.now
      @user = User.find(params[:current_user_id])

      filter_params = params[:filter]
      disability_types = permitted_disability_types(filter_params[:disabilities])
      permitted_filter = filter_params.merge(disabilities: disability_types.map(&:to_s))
      report.parameters = params.merge(filter: permitted_filter)

      report.user_id = @user.id
      report.parameters[:visible_projects] = if GrdaWarehouse::DataSource.can_see_all_data_sources?(@user)
        [:all, 'All']
      else
        project_source.pluck(:id, :ProjectName)
      end

      clients = []
      if disability_types.empty?
        clients = client_source.none
      else
        start_date = filter_params[:start].to_date
        end_date = filter_params[:end].to_date

        enrollment_scope = service_history_enrollment_source.entry.
          open_between(start_date: start_date, end_date: end_date).
          in_project_type(filter_params[:project_types])

        population = service_history_enrollment_source.known_standard_cohorts.detect { |m| m.to_s == filter_params[:sub_population] }
        enrollment_scope = enrollment_scope.send(population) if population.present?

        enrollment_scope = enrollment_scope.heads_of_households if filter_params[:heads_of_household]

        enrollment_scope = enrollment_scope.in_age_ranges(filter_params[:age_ranges], on_date: start_date)

        clients = client_source.joins(source_disabilities: :project, source_enrollments: :service_history_enrollment).
          merge(GrdaWarehouse::Hud::Disability.where(DisabilityType: disability_types, DisabilityResponse: [1, 2, 3])).
          merge(GrdaWarehouse::Hud::Project.with_project_type(filter_params[:project_types].reject(&:blank?))).
          merge(project_source).
          merge(enrollment_scope).
          distinct.
          includes(source_disabilities: :project, source_enrollments: :service_history_enrollment).
          select(*client_columns)
      end
      data = []
      clients.find_each do |client|
        disabilities = client.source_disabilities.map(&:disability_type_text).uniq
        attrs = client.attributes.slice(*client_columns).merge(disabilities: disabilities)

        enrollments = client.source_enrollments.map(&:service_history_enrollment).compact
        enrollment = enrollments.map { |r| r.attributes.compact }.reduce(&:merge)
        data << attrs.merge(enrollment: enrollment)
      end

      report.client_count = clients.size
      report.finished_at = DateTime.now
      report.data = data
      # The controller validated the request; skip the parameter validation here so a report
      # whose types were all removed for lack of permission still saves as an empty report.
      report.save(validate: false)

      NotifyUser.enrolled_disabled_report_finished(params[:current_user_id], report.id).deliver_later
    end

    # The job must enforce sensitive-type permissions itself; it can't trust the posted list.
    private def permitted_disability_types(requested)
      # Raise on a missing label so a renamed HUD value can't silently skip the exclusion
      hud_util = ::HudHelper.util
      excluded = []
      excluded << hud_util.disability_type('HIV/AIDS', true, raise_on_missing: true) unless @user.can_view_hiv_status?
      excluded << hud_util.disability_type('Mental health disorder', true, raise_on_missing: true) unless @user.can_view_dmh_status?

      requested_types = Array(requested).reject(&:blank?).map(&:to_i)
      requested_types - excluded
    end

    def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    def project_source
      GrdaWarehouse::Hud::Project.viewable_by(@user, permission: :can_view_assigned_reports)
    end

    def service_history_enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    def client_columns
      @client_columns ||= [
        'id',
        'PersonalID',
        'data_source_id',
        'FirstName',
        'LastName',
        'DOB',
        'VeteranStatus',
      ]
    end
  end
end
