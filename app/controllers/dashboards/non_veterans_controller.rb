module Dashboards
  class NonVeteransController < BaseController
    include ArelHelper

    before_action :require_can_view_censuses!
    
    def sub_population_key
      :non_veteran
    end
    helper_method :sub_population_key

    def active_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::NonVeteran::ActiveClients
    end

    def housed_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::NonVeteran::HousedClients
    end

    def entered_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::NonVeteran::EnteredClients
    end
  end
end