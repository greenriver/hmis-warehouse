module Dashboards
  class ParentingChildrensController < BaseController
    include ArelHelper

    before_action :require_can_view_censuses!
    
    def sub_population_key
      :parenting_children
    end
    helper_method :sub_population_key

    def active_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::ParentingChildren::ActiveClients
    end

    def housed_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::ParentingChildren::HousedClients
    end

    def entered_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::ParentingChildren::EnteredClients
    end
  end
end