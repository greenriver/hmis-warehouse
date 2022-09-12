###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ClientAccessControl::ClientsController < ApplicationController
  include AjaxModalRails::Controller
  include ClientAccessControl::SearchConcern
  include ClientAccessControl::ClientConcern
  include ClientShowPages
  include ArelHelper
  include ClientPathGenerator

  helper ClientHelper

  before_action :require_can_access_some_client_search!, only: [:index, :simple]
  before_action :require_can_view_clients!, only: [:show, :service_range, :rollup, :image]
  before_action :require_can_view_enrollment_details_tab!, only: [:enrollment_details]
  before_action :require_can_see_this_client_demographics!, except: [:index, :simple, :appropriate, :new, :from_source]
  before_action :set_client, only: [:show, :service_range, :rollup, :image, :enrollment_details]
  before_action :require_can_create_clients!, only: [:new]
  before_action :set_search_client, only: [:simple, :appropriate, :from_source]
  before_action :set_client_start_date, only: [:show, :rollup]
  after_action :log_client, only: [:show]

  def index
    @show_ssn = GrdaWarehouse::Config.get(:show_partial_ssn_in_window_search_results) || can_view_full_ssn?
    # search
    @clients = client_scope.none
    if current_user.can_use_strict_search?
      @clients = client_source.strict_search(strict_search_params, client_scope: client_search_scope)
    elsif (current_user.can_access_window_search? || current_user.can_search_own_clients?) && params[:q].present?
      @clients = client_source.text_search(params[:q], client_scope: client_search_scope)
    end
    preloads = [
      :processed_service_history,
      :vispdats,
      source_clients: :data_source,
      non_confidential_user_clients: :user,
    ]
    if health_emergency?
      preloads += [
        :health_emergency_ama_restrictions,
        :health_emergency_triages,
        :health_emergency_tests,
        :health_emergency_isolations,
        :health_emergency_quarantines,
      ]
    end
    if healthcare_available?
      preloads += [
        :patient,
      ]
    end

    @clients = @clients.
      distinct.
      destination.
      preload(preloads)

    @pagy, @clients = pagy(@clients)

    if current_user.can_use_strict_search?
      @client = client_source.new(strict_search_params)
      render 'strict_search'
    elsif current_user.can_access_window_search? || current_user.can_search_own_clients?
      sort_filter_index
    end
  end

  def show
    @show_ssn = GrdaWarehouse::Config.get(:show_partial_ssn_in_window_search_results) || can_view_full_ssn?
    log_item(@client)
    @note = GrdaWarehouse::ClientNotes::Base.new
  end

  def new
    @existing_matches ||= []
    @client = client_source.new
  end

  def simple
    @show_ssn = GrdaWarehouse::Config.get(:show_partial_ssn_in_window_search_results) || can_view_full_ssn?
  end

  # It can be expensive to calculate the appropriate link to show a user for a batch of clients
  # instead, just provide one where we can make that determination on a per-client basis
  def appropriate
    redirect_to @client.appropriate_path_for?(current_user)
  end

  def from_source
    source_client = GrdaWarehouse::Hud::Client.source_visible_to(current_user).find(params[:id])
    @client = source_client.destination_client
    redirect_to @client.appropriate_path_for?(current_user)
  end

  def image
    max_age = if request.headers['Cache-Control'].to_s.include? 'no-cache'
      0
    else
      30.minutes
    end
    response.headers['Last-Modified'] = Time.zone.now.httpdate
    expires_in max_age, public: false
    image = @client.image(max_age)
    if image && ! Rails.env.test?
      send_data image, type: ::MimeMagic.by_magic(image), disposition: 'inline'
    else
      head(:forbidden)
      nil
    end
  end

  def enrollment_details
  end

  private def client_source
    GrdaWarehouse::Hud::Client
  end

  private def client_scope(id: nil)
    source_client_ids = GrdaWarehouse::WarehouseClient.where(destination_id: id).pluck(:source_id).presence
    client_source.destination_visible_to(current_user, source_client_ids: source_client_ids).where(id: id)
  end

  # Should always return any clients, source or destination that match
  def client_search_scope
    client_source.searchable_to(current_user)
  end

  private def project_scope
    GrdaWarehouse::Hud::Project
  end

  private def service_history_service_scope
    GrdaWarehouse::ServiceHistoryService
  end

  private def set_client_start_date
    @start_date = @client.date_of_first_service
  end

  private def set_potential_matches
    @potential_matches = @client.potential_matches
  end

  # Only allow a trusted parameters.
  private def client_params
    params.require(:grda_warehouse_hud_client).
      permit(
        :hmis_receiver,
        :health_receiver,
        merge: [],
        unmerge: [],
      )
  end

  private def strict_search_params
    return {} unless params[:client].present?

    params.require(:client).
      permit(
        :first_name,
        :last_name,
        :dob,
        :ssn,
      )
  end

  private def assessment_scope
    if can_view_clients?
      GrdaWarehouse::HmisForm
    else
      GrdaWarehouse::HmisForm.window_with_details
    end
  end

  private def health_assessment_scope
    GrdaWarehouse::HmisForm.health
  end

  private def log_client
    log_item(@client)
  end

  private def dp(table, part, date)
    datepart table, part, date
  end
  helper_method :dp
end
