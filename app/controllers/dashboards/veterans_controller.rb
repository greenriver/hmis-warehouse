module Dashboards
  class VeteransController < BaseController
    include ArelHelper

    before_action :require_can_view_censuses!
    
    def client_source
      GrdaWarehouse::Hud::Client.destination.veteran
    end

    def service_history_source
      GrdaWarehouse::ServiceHistory
    end

    def sub_population_key
      :veteran
    end
    helper_method :sub_population_key

    def active_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::Veteran::ActiveClients
    end

    def housed_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::Veteran::HousedClients
    end

    def entered_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::Veteran::EnteredClients
    end
  end
end