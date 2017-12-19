module Dashboards
  class IndividualAdultsController < BaseController
    include ArelHelper

    before_action :require_can_view_censuses!
    
    def sub_population_key
      :individual_adults
    end
    helper_method :sub_population_key

    def active_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::IndividualAdult::ActiveClients
    end

    def housed_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::IndividualAdult::HousedClients
    end

    def entered_report_class
      GrdaWarehouse::WarehouseReports::Dashboard::IndividualAdult::EnteredClients
    end
  end
end