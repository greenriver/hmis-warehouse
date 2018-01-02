module WarehouseReports
  class RunEnrolledDisabledJob < ActiveJob::Base

    queue_as :enrolled_disabled_report

    def perform params
      report = GrdaWarehouse::WarehouseReports::EnrolledDisabledReport.new
      report.started_at = DateTime.now
      report.parameters = params

      filter_params = params[:filter]

      clients = []
      if filter_params[:disabilities].empty?
        clients = client_source.none
      else
        clients = client_source.joins(source_disabilities: :project, source_enrollments: :service_histories).
          where(Disabilities: {DisabilityType: filter_params[:disabilities], DisabilityResponse: [1,2,3]}).
          where(Project: {project_source.project_type_column => filter_params[:project_types]}).
          merge(history.entry.ongoing.where(history.project_type_column => filter_params[:project_types])).
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
      GrdaWarehouse::Hud::Project
    end

    def history
      GrdaWarehouse::ServiceHistory
    end

  end
end