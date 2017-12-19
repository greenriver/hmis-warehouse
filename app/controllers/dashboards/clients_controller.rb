module Dashboards
  class ClientsController < BaseController
    include ArelHelper

    before_action :require_can_view_censuses!
    
    def sub_population_key
      :all_clients
    end
    helper_method :sub_population_key

    def active_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::AllClients::ActiveClients
    end

    def housed_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::AllClients::HousedClients
    end

    def entered_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::AllClients::EnteredClients
    end
  end
end