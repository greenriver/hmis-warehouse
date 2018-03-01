module Clients
  class HistoryController < Window::Clients::HistoryController
    include ClientPathGenerator
    
    skip_before_action :check_release
    before_action :require_can_view_client_and_history!
    
    def name_for_project project_name
      project_name
    end

    def enrollment_scope
      @client.service_history_enrollments
    end
        
    def client_scope
      client_source.destination.joins(source_clients: :data_source)
    end
  
  end
end
