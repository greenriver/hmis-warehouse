module WarehouseReports
  class NonAlphaNamesController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    def index
      ct = client_source.arel_table
      @clients = client_source
        .where( fc_non_alpha(ct[:LastName]).or fc_non_alpha ct[:FirstName] )
        .order(:LastName, :FirstName)
      respond_to do |format|
        format.html {
          @clients = @clients.page(params[:page]).per(25)
        }
        format.xlsx {}
      end
    end

    def related_report
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: 'warehouse_reports/non_alpha_names')
    end

    # dbms-agnostic code in place of LastName like '[^a-Z]%' or FirstName like '[^a-Z]%'
    private def fc_non_alpha(exp)
      nf( 'LOWER', [nf( 'SUBSTRING', [ exp, 1, 1 ] )] ).not_in ('a'..'z').to_a
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end
  end
end
