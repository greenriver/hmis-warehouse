module Dashboards
  class ChildrensController < BaseController
    include ArelHelper

    before_action :require_can_view_censuses!
    
    def sub_population_key
      :children
    end
    helper_method :sub_population_key

    def active_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::Children::ActiveClients
    end

    def housed_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::Children::HousedClients
    end

    def entered_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::Children::EnteredClients
    end
  end
end