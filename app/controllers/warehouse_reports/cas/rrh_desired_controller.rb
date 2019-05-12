module WarehouseReports::Cas
  class RrhDesiredController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization

    def index
      @clients = client_source
    end


    def client_source
      GrdaWarehouse::Hud::Client.destination.no_release_on_file.desiring_rrh
    end

  end
end
