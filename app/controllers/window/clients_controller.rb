module Window
  class ClientsController < ApplicationController
    include PjaxModalController
    include ClientController
    include WindowClientPathGenerator

    helper ClientHelper
    
    before_action :require_can_search_window!, only: [:index]
    before_action :require_can_see_this_client_demographics!, except: [:index, :new, :create]
    before_action :set_client, :check_release, only: [:show]
    before_action :set_client_from_client_id, only: [:image, :rollup]
    before_action :require_can_create_clients!, only: [:new, :create]
    after_action :log_client, except: [:rollup, :image]

    def index
      @show_ssn = GrdaWarehouse::Config.get(:show_partial_ssn_in_window_search_results)
      # search
      @clients = if params[:q].present?
        client_source.text_search(params[:q], client_scope: client_search_scope)
      else
        client_scope.none
      end
      @clients = @clients.preload(:processed_service_history)
      sort_filter_index()

    end

    def show
      log_item(@client)
    end

    # display an assessment form in a modal
    # for the window, we require both a full release for the client
    # and details visible in the window on the assessment
    def assessment
      @client = client_scope.find(params[:client_id].to_i)
      if @client&.consent_form_valid?
        @form = assessment_scope.find(params.require(:id).to_i)
      else
        @form = assessment_scope.new
      end
      render 'assessment_form'
    end

    private def client_source
      GrdaWarehouse::Hud::Client
    end

    private def client_scope
      client_source.joins(source_clients: :data_source).merge(GrdaWarehouse::DataSource.visible_in_window_to(current_user))
    end

    private def assessment_scope
      GrdaWarehouse::HmisForm.window_with_details
    end

    def client_search_scope
      client_source.searchable.joins(:data_source).merge(GrdaWarehouse::DataSource.visible_in_window_to(current_user))
    end

    def set_client_from_client_id
      @client = client_source.find(params[:client_id].to_i)
    end

    def user_can_view_confidential_names?
      false
    end

  end
end
