module WarehouseReports::Cas
  class RrhDesiredController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization

    def index
      @clients = client_source.joins(:source_hmis_forms).
        references(:source_hmis_forms).
        merge(GrdaWarehouse::HmisForm.rrh_assessment).
        order(hmis_form_t[:collected_at].desc)
    end


    def client_source
      GrdaWarehouse::Hud::Client.destination.no_release_on_file
    end

  end
end
