module WarehouseReports
  class FutureEnrollmentsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_limited, only: [:index]
    def index
      et = GrdaWarehouse::Hud::Enrollment.arel_table
      @clients = client_source.
        joins(source_enrollments: :project).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user)).
        preload(:source_enrollments).
        where( et[:EntryDate].gt(Date.today) ).
        order(:LastName, :FirstName).
        page(params[:page]).per(25)
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end
  end
end
