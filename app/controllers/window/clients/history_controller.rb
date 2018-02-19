module Window::Clients
  class HistoryController < ApplicationController
    include WindowClientPathGenerator
    
    before_action :require_can_see_this_client_demographics!
    before_action :set_client, :check_release
    before_action :set_dates, only: [:show]
    
    def show
      @ordered_dates = @dates.keys.sort
      @start = @ordered_dates.first
      @end = @ordered_dates.last
      @date_range = (@start.beginning_of_month..@end.end_of_month)
      @months = @date_range.map do |date|
        [date.year, date.month]
      end.uniq
    end

    def set_dates
      @dates = {}
      enrollment_scope.
        includes(:service_history_services, :organization).
        each do |enrollment|
          project_type = enrollment.project_type
          project_name = name_for_project(enrollment.project_name)
          @dates[enrollment.date] ||= []
          record = {
            record_type: enrollment.record_type,
            project_type: project_type,
            project_name: project_name,
            organization_name: nil,
          }
          unless project_name == GrdaWarehouse::Hud::Project.confidential_project_name
            record[:organization_name] = enrollment.organization.OrganizationName
          end
          @dates[enrollment.date] << record
          enrollment.service_history_services.each do |service|
            @dates[service.date] ||= []
            @dates[service.date] << {
              record_type: service.record_type,
              project_type: project_type,
              project_name: project_name,
              organization_name: nil,
            }
          end
        end
    end

    def name_for_project project_name
      GrdaWarehouse::Hud::Project.confidentialize(name: project_name)
    end

    def enrollment_scope
      @client.service_history_enrollments.visible_in_window
    end
    
    def set_client
      @client = client_scope.find(params[:client_id].to_i)
    end
    alias_method :set_client_from_client_id, :set_client
    
    def client_source
      GrdaWarehouse::Hud::Client
    end
    
    def client_scope
      client_source.destination.
        joins(source_clients: :data_source).
        where(data_sources: {visible_in_window: true})
    end
  end
end
