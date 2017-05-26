module WarehouseReports
  class ActiveVeteransController < ApplicationController
    before_action :require_can_view_reports!
    def index
      @sort_options = sort_options
      date_range_options = params.permit(range: [:start, :end])[:range]
      @range = DateRange.new(date_range_options)
      @column = sort_column
      @direction = sort_direction
      @served_client_ids = service_history_source.
        service_within_date_range(start_date: @range.start, end_date: @range.end).
        select(:client_id).distinct
      @clients = client_source.
        preload(:source_clients).
        includes(:processed_service_history).
        joins(:processed_service_history).
        where(id: @served_client_ids).
        order(sort_options[{column: @column, direction: @direction}][:column])
      
      respond_to do |format|
        format.html do
          @clients = @clients.page(params[:page]).per(50)
          @enrollments = service_history_source.entry.
            open_between(start_date: @range.start, end_date: @range.end + 1.day).
            includes(:enrollment).
            joins(:data_source).
            where(client_id: @clients.map(&:id)).pluck(*service_history_columns.values).
            map do |row|
              Hash[service_history_columns.keys.zip(row)]
            end.
            group_by{|m| m[:client_id]}

        end
        format.xlsx do
          @enrollments = service_history_source.entry.
            open_between(start_date: @range.start, end_date: @range.end + 1.day).
            includes(:enrollment).
            joins(:data_source).
            where(client_id: @clients.map(&:id)).pluck(*service_history_columns.values).
            map do |row|
              Hash[service_history_columns.keys.zip(row)]
            end.
            group_by{|m| m[:client_id]}
        end
      end
    end

    
    private def client_source
      GrdaWarehouse::Hud::Client.destination.veteran
    end
    private def service_history_source
      GrdaWarehouse::ServiceHistory.where(project_type: GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values_at(:es, :th, :so, :sh).flatten.uniq.sort)
    end

    private def service_history_columns
      enrollment_table = GrdaWarehouse::Hud::Enrollment.arel_table
      ds_table = GrdaWarehouse::DataSource.arel_table
      service_history_columns = {
        client_id: :client_id, 
        project_id: :project_id, 
        first_date_in_program: :first_date_in_program, 
        last_date_in_program: :last_date_in_program, 
        project_name: :project_name, 
        project_type: :project_type, 
        organization_id: :organization_id, 
        data_source_id: :data_source_id,
        PersonalID: enrollment_table[:PersonalID].as('PersonalID').to_sql,
        ds_short_name: ds_table[:short_name].as('short_name').to_sql,
      }
    end
    
    private def sort_column
      sort_options.map{|k,_| k[:column]}.uniq.
        include?(params[:sort]) ? params[:sort] : 'first_date_served'
    end

    private def sort_direction
      direction = params[:direction].to_sym
      [:asc, :desc].include?(direction) ? direction : :asc
    end

    private def sort_options
      @sort_options ||= begin 
        ct = GrdaWarehouse::Hud::Client.arel_table
        wcpt = GrdaWarehouse::WarehouseClientsProcessed.arel_table
        
        {
          {column: 'LastName', direction: :asc} => {
            title: 'Last name A-Z', 
            column: ct[:LastName].asc, 
            param: 'LastName',
          },
          {column: 'LastName', direction: :desc} => {
            title: 'Last name Z-A', 
            column: ct[:LastName].desc,
            param: 'LastName',
          },
          {column: 'days_served', direction: :desc} => {
            title: 'Most served', 
            column: wcpt[:days_served].desc, 
            param: 'days_served',
          },
          {column: 'first_date_served', direction: :asc} => {
            title: 'Longest standing', 
            column: wcpt[:first_date_served].asc, 
            param: 'first_date_served',
          },
        }
        
      end
    end
  end
end
