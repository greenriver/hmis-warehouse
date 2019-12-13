###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class RunEnrolledDisabledJob < BaseJob
    queue_as :enrolled_disabled_report

    def perform(params)
      report = GrdaWarehouse::WarehouseReports::EnrolledDisabledReport.new
      report.started_at = DateTime.now
      report.parameters = params

      @user = User.find(params[:current_user_id])

      report.user_id = @user.id
      report.parameters[:visible_projects] = if @user.can_edit_anything_super_user?
        [:all, 'All']
      else
        GrdaWarehouse::Hud::Project.viewable_by(@user).pluck(:id, :ProjectName)
      end

      filter_params = params[:filter]

      clients = []
      if filter_params[:disabilities].empty?
        clients = client_source.none
      else
        start_date = filter_params[:start].to_date
        end_date = filter_params[:end].to_date

        enrollment_scope = service_history_enrollment_source.entry.
          open_between(start_date: start_date, end_date: end_date).
          in_project_type(filter_params[:project_types])

        population = service_history_enrollment_source.know_standard_cohorts.detect { |m| m.to_s == filter_params[:sub_population] }
        enrollment_scope = enrollment_scope.send(population) if population.present?

        clients = client_source.joins(source_disabilities: :project, source_enrollments: :service_history_enrollment).
          merge(GrdaWarehouse::Hud::Disability.where(DisabilityType: filter_params[:disabilities], DisabilityResponse: [1, 2, 3])).
          merge(GrdaWarehouse::Hud::Project.with_project_type(filter_params[:project_types])).
          merge(enrollment_scope).
          distinct.
          includes(source_disabilities: :project, source_enrollments: :service_history_enrollment).
          order(LastName: :asc, FirstName: :asc)
      end

      data = clients.map do |client|
        disabilities = client.source_disabilities.map(&:disability_type_text).uniq
        attrs = client.attributes.merge(disabilities: disabilities)

        enrollments = client.source_enrollments.map(&:service_history_enrollment).compact
        enrollment = enrollments.map { |r| r.attributes.compact }.reduce(&:merge)
        attrs.merge(enrollment: enrollment)
      end

      report.client_count = clients.size
      report.finished_at = DateTime.now
      report.data = data.to_json
      report.save

      NotifyUser.enrolled_disabled_report_finished(params[:current_user_id], report.id).deliver_later
    end

    def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    def project_source
      GrdaWarehouse::Hud::Project.viewable_by(@user)
    end

    def service_history_enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end
  end
end
