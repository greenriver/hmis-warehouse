module WarehouseReports
  class ReallyOldEnrollmentsController < ApplicationController
    before_action :require_can_view_reports!
    def index
      @date = (params[:date] || '1980-01-01').to_date
      et = GrdaWarehouse::Hud::Enrollment.arel_table
      @clients = client_source
        .joins(:source_enrollments)
        .preload(:source_enrollments)
        .where( et[:EntryDate].lt @date )
        .order(:LastName, :FirstName)
        .page(params[:page]).per(25)
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end
  end
end