###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::WarehouseReports
  class OutflowReport
    def initialize(filter)
      @filter = filter
    end

    def clients_to_ph
      @clients_to_ph ||= []
    end

    def psh_clients_to_stabilization
      @psh_clients_to_stabilization ||= []
    end

    def rrh_clients_to_stabilization
      @rrh_clients_to_stabilization ||= []
    end

    def clients_to_stabilization
      @clients_to_stabilization ||= (psh_clients_to_stabilization + rrh_clients_to_stabilization).uniq
    end

    def clients_without_recent_service
      @clients_without_recent_service ||= []
    end

    def client_outflow
      @client_outflow ||= (clients_to_ph + clients_to_stabilization + clients_without_recent_service).uniq
    end

  end
end