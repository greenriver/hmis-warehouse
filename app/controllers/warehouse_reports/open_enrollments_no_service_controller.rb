module WarehouseReports
  class OpenEnrollmentsNoServiceController < ApplicationController
    include WarehouseReportAuthorization
    def index
      @sort_options = sort_options
      date_range_options = params.permit(range: [:start, :end])[:range]
      @range = ::Filters::DateRange.new(date_range_options)
      @column = sort_column
      @direction = sort_direction

      cutoff = Date.today - 30.days
      key = [:data_source_id, :project_id, :enrollment_group_id, :project_name, :first_date_in_program, :client_id]
      sh = service_history_source.arel_table
      open_enrollments = service_history_source.select(*key).
        entry.ongoing.bed_night.
        where(sh[:first_date_in_program].lt(cutoff)).
        distinct.
        pluck(*key)
      service_in_last_30_days = service_history_source.select(*key).
        service.ongoing.bed_night.
        where(sh[:date].gt(cutoff)).
        distinct.
        pluck(*key)
      open_enrollments_no_service = open_enrollments - service_in_last_30_days
      enrollment_groups = open_enrollments_no_service.map do |_, _, enrollment_group_id, _, _, _|
          enrollment_group_id
        end
      respond_to do |format|
        format.html do
          @entries = service_history_source.entry.
            where(enrollment_group_id: enrollment_groups).
            page(params[:page]).per(50)
          client_ids = @entries.map(&:client_id)
          @clients = client_source.where(id: client_ids).
            pluck(:id, :FirstName, :LastName).map do |row|
              Hash[[:id, :FirstName, :LastName].zip(row)]
            end.index_by{ |m| m[:id]}
          @max_dates = service_history_source.select(*key).
            service.ongoing.bed_night.
            where(project_tracking_method: 3).
            where(enrollment_group_id: @entries.map(&:enrollment_group_id)).
            group(key).
            maximum(:date)
        end
        format.xlsx do      
          client_ids = open_enrollments.map{|_, _, _, _, _, client_id| client_id}
          @clients = client_source.where(id: client_ids).
            pluck(:id, :FirstName, :LastName).map do |row|
              Hash[[:id, :FirstName, :LastName].zip(row)]
            end.index_by{ |m| m[:id]}
          @max_dates = service_history_source.select(*key).
            service.ongoing.bed_night.
            where(project_tracking_method: 3).
            where(enrollment_group_id: enrollment_groups).
            group(key).
            maximum(:date)
          @entries = open_enrollments_no_service.map do |row|
            Hash[key.zip(row)]
          end
        end
      end
    end

    def related_report
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: 'warehouse_reports/open_enrollments_no_service')
    end
    
    private def client_source
      GrdaWarehouse::Hud::Client
    end
    private def service_history_source
      GrdaWarehouse::ServiceHistory
    end

    private def sort_column
      sort_options.map{|m| m[:column]}.uniq.
        include?(params[:sort]) ? params[:sort] : "#{GrdaWarehouse::ServiceHistory.quoted_table_name}.first_date_in_program"
    end

    private def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end

    private def sort_options
      [
        # {
        #   title: 'Last name A-Z', 
        #   column: "#{GrdaWarehouse::Hud::Client.quoted_table_name}.LastName", 
        #   direction: 'asc'
        # },
        # {
        #   title: 'Last name Z-A', 
        #   column: "#{GrdaWarehouse::Hud::Client.quoted_table_name}.LastName", 
        #   direction: 'desc'
        # },
        {
          title: 'Project', 
          column: "#{GrdaWarehouse::ServiceHistory.quoted_table_name}.project_name", 
          direction: 'asc'
        },
        {
          title: 'Longest', 
          column: "#{GrdaWarehouse::ServiceHistory.quoted_table_name}.first_date_in_program", 
          direction: 'asc'
        },
        {
          title: 'Shortest', 
          column: "#{GrdaWarehouse::ServiceHistory.quoted_table_name}.first_date_in_program", 
          direction: 'desc'
        },
        # {
        #   title: 'Most Recently Seen', 
        #   column: "max_date", 
        #   direction: 'desc'
        # },
      ]
    end

    private def cols
      [
        :id,
        :enrollment_group_id, 
        :data_source_id, 
        :project_id,
        :organization_id,
        :project_name,
        :first_date_in_program,
        :client_id,
      ]
    end
  end
end
