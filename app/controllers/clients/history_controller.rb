###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Clients
  class HistoryController < Window::Clients::HistoryController
    include ClientPathGenerator
    
    skip_before_action :check_release
    before_action :require_can_view_client_and_history!
    after_action :log_client
    
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
