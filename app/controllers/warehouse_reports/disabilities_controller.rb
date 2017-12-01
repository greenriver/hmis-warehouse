module WarehouseReports
  class DisabilitiesController < ApplicationController
    before_action :require_can_view_all_reports!

    def index
      @filter = DisabilityProjectTypeFilter.new(filter_params)
      affirmative_responses = [1,2,3]
      if @filter.disabilities.empty?
        @clients = client_source.none
      else
        @clients = client_source.joins(source_disabilities: :project, source_enrollments: :service_histories).
          where(Disabilities: {DisabilityType: @filter.disabilities, DisabilityResponse: affirmative_responses}).
          where(Project: {project_source.project_type_column => @filter.project_types}).
          merge(history.entry.ongoing.where(history.project_type_column => @filter.project_types)).
          distinct.
          includes(source_disabilities: :project).
          order(LastName: :asc, FirstName: :asc)
      end
      respond_to do |format|
        format.html {
          @clients = @clients.page(params[:page]).per(25)
        }
        format.xlsx {}
      end
    end

    def filter_params
      params.require(:filter).permit(
        disabilities: [],
        project_types: [],
      ) rescue {}
    end

    def available_disabilities
      ::HUD.disability_types.invert
    end
    helper_method :available_disabilities

    def available_project_types
      ::HUD.project_types.invert
    end
    helper_method :available_project_types

    private def history
      GrdaWarehouse::ServiceHistory
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    def project_source
      GrdaWarehouse::Hud::Project
    end

    def history_source
      GrdaWarehouse::ServiceHistory
    end

    class DisabilityProjectTypeFilter < ModelForm
      attribute :disabilities, Date, lazy: true, default: []
      attribute :project_types, Date, lazy: true, default: []

    end
  end
end
