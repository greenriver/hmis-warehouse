module WarehouseReports
  class RunActiveVeteransJob < ActiveJob::Base

    queue_as :active_veterans_report

    def perform params
      report = GrdaWarehouse::WarehouseReports::ActiveVeteransReport.new
      report.started_at = DateTime.now
      report.parameters = params

      range = ::Filters::DateRangeAndProject.new(params['range'])
      scope = service_history_scope

      project_types = range.project_type.select(&:present?).map(&:to_sym)
      if project_types.any?
        scope = scope.where( service_history_source.project_type_column => project_types.flat_map{ |t| project_source::RESIDENTIAL_PROJECT_TYPES[t] } )
      end

      served_client_ids = scope.service_within_date_range(start_date: range.start, end_date: range.end).select(:client_id).distinct

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
        group_by{|m| m[:client_id]}

      data = clients.map do |client|

        data_sources = client.source_clients.map do |sc|
          if sc.VeteranStatus == 1
            GrdaWarehouse::DataSource.short_name(sc.data_source_id)
          end
        end
        client.attributes.merge(
          name: client.name,
          enrollments: enrollments[client.id],
          first_service_history: client&.first_service_history&.date,
          data_sources: data_sources.uniq.compact,
          days_served: client.processed_service_history.days_served,
          first_date_served: client.processed_service_history.first_date_served
        )
      end

      report.client_count = clients.size
      report.finished_at = DateTime.now
      report.data = data.to_json
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
      service_history_columns = {
        client_id: :client_id, 
        project_id: :project_id, 
        first_date_in_program: :first_date_in_program, 
        last_date_in_program: :last_date_in_program, 
        project_name: :project_name, 
        project_type: service_history_source.project_type_column,
        data_source_id: :data_source_id,
        PersonalID: enrollment_table[:PersonalID].as('PersonalID').to_sql,
        ds_short_name: ds_table[:short_name].as('short_name').to_sql,
      }
    end
    
    def service_history_source
      GrdaWarehouse::ServiceHistory
    end

  end
end