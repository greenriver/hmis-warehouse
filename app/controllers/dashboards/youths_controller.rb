module Dashboards
  class YouthsController < BaseController
    include ArelHelper

    before_action :require_can_view_censuses!
    
    def sub_population_key
      :youths
    end
    helper_method :sub_population_key

    def active_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::Youth::ActiveClients
    end

    def housed_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::Youth::HousedClients
    end

    def entered_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::Youth::EnteredClients
    end
  end
end