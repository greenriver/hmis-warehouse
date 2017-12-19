module Dashboards
  class ParentingYouthsController < BaseController
    include ArelHelper

    before_action :require_can_view_censuses!
    
    def sub_population_key
      :parenting_youths
    end
    helper_method :sub_population_key

    def active_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::ParentingYouth::ActiveClients
    end

    def housed_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::ParentingYouth::HousedClients
    end

    def entered_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::ParentingYouth::EnteredClients
    end
  end
end