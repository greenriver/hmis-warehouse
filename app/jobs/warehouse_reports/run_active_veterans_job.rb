###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class RunActiveVeteransJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(params)
      report = GrdaWarehouse::WarehouseReports::ActiveVeteransReport.new
      report.started_at = DateTime.now
      report.parameters = params

      user = User.find(params[:current_user_id])
      report.user_id = user.id
      report.parameters[:visible_projects] = if user.can_view_all_reports?
        [:all, 'All']
      else
        GrdaWarehouse::Hud::Project.viewable_by(user).pluck(:id, :ProjectName)
      end

      range = ::Filters::DateRangeAndProject.new(params['range'])
      scope = service_history_scope.joins(:project).merge(GrdaWarehouse::Hud::Project.viewable_by(user))

      project_types = range.project_type.select(&:present?).map(&:to_sym)
      scope = scope.where(service_history_source.project_type_column => project_types.flat_map { |t| project_source::RESIDENTIAL_PROJECT_TYPES[t] }) if project_types.any?

      served_client_ids = scope.service_within_date_range(start_date: range.start, end_date: range.end).distinct.select(:client_id)

      clients = GrdaWarehouse::Hud::Client.destination.
        veteran.
        preload(:source_clients).
        includes(:processed_service_history).
        joins(:processed_service_history).
        where(id: served_client_ids)

      enrollments = scope.entry.open_between(start_date: range.start, end_date: range.end + 1.day).
        includes(:enrollment).
        joins(:data_source, :project).
        where(client_id: clients.map(&:id)).pluck(*service_history_columns.values).
        map do |row|
          Hash[service_history_columns.keys.zip(row)]
        end.
        compact.
        group_by { |m| m[:client_id] }

      # remove anyone who doesn't actually have an open enrollment during the time (these can be added by extrapolated SO or poor data where we have service on the exit date)
      clients = clients.select { |c| enrollments.key?(c.id) }

      data = clients.map do |client|
        data_sources = client.source_clients.map do |sc|
          GrdaWarehouse::DataSource.short_name(sc.data_source_id) if sc.VeteranStatus == 1
        end
        data_source_ids = client.source_clients.map(&:data_source_id)
        client.attributes.merge(
          name: client.name,
          enrollments: enrollments[client.id],
          first_service_history: client.date_of_first_service,
          data_sources: data_sources.uniq.compact,
          data_source_ids: data_source_ids.uniq.compact,
          days_served: client.processed_service_history.days_served,
          first_date_served: client.processed_service_history.first_date_served,
        )
      end
      report.client_count = clients.size
      report.finished_at = DateTime.now
      report.data = data
      report.save

      NotifyUser.active_veterans_report_finished(params[:current_user_id], report.id).deliver_later
    end

    def service_history_scope
      project_types = project_source::RESIDENTIAL_PROJECT_TYPES.values_at(:es, :th, :so, :sh).flatten.uniq.sort
      service_history_source.where(service_history_source.project_type_column => project_types)
    end

    def project_source
      GrdaWarehouse::Hud::Project
    end

    def service_history_columns
      enrollment_table = GrdaWarehouse::Hud::Enrollment.arel_table
      ds_table = GrdaWarehouse::DataSource.arel_table
      {
        client_id: :client_id,
        project_id: :project_id,
        first_date_in_program: :first_date_in_program,
        last_date_in_program: :last_date_in_program,
        project_name: :project_name,
        project_type: service_history_source.project_type_column,
        data_source_id: :data_source_id,
        PersonalID: enrollment_table[:PersonalID].as('PersonalID'),
        ds_short_name: ds_table[:short_name].as('short_name'),
        ds_id: ds_table[:id].as('ds_id'),
      }
    end

    def service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end
  end
end
