module WarehouseReports
  class RrhController < ApplicationController
    include WarehouseReportAuthorization
    def index

    end

    private def housed_source
      Reporting::Housed
    end

    private def returns_source
      Reporting::Return
    end

  end
end
