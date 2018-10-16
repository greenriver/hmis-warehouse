module WarehouseReports
  class RunEnrolledDisabledJob < BaseJob

    queue_as :enrolled_disabled_report

    def perform params
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
        clients = client_source.joins(source_disabilities: :project, source_enrollments: :service_history_enrollment).
          where(Disabilities: {DisabilityType: filter_params[:disabilities], DisabilityResponse: [1,2,3]}).
          where(Project: {project_source.project_type_column => filter_params[:project_types]}).
          merge(service_history_enrollment_source.entry.ongoing.in_project_type(filter_params[:project_types])).
          distinct.
          includes(source_disabilities: :project).
          order(LastName: :asc, FirstName: :asc)
      end

      data = clients.map do |client|
        disabilities = client.source_disabilities.map(&:disability_type_text).uniq
        client.attributes.merge(disabilities: disabilities)
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