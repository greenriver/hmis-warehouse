module WarehouseReports
  class RrhController < ApplicationController
    include WarehouseReportAuthorization

    respond_to :html, :js
    
    def index
      @programs_for_select = Reporting::D3Charts.programs_for_select
    end

    def program_data
      @program_1_id = params[:program_1_id]
      @program_2_id = params[:program_2_id]
      @charts = Reporting::D3Charts.new(@program_1_id, @program_2_id)
    end

    private def housed_source
      Reporting::Housed
    end

    private def returns_source
      Reporting::Return
    end

  end
end
