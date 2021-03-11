###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ClientAccessControl::ClientsController < ApplicationController
  include AjaxModalRails::Controller
  # include ClientController
  include ClientAccessControl::SearchConcern
  include ArelHelper
  include ClientPathGenerator

  helper ClientHelper

  before_action :require_can_access_some_client_search!, only: [:index, :simple]

  def index
    @show_ssn = GrdaWarehouse::Config.get(:show_partial_ssn_in_window_search_results) || can_view_full_ssn?
    # search
    @clients = client_scope.none
    if (current_user.can_access_window_search? || current_user.can_access_client_search?) && params[:q].present?
      @clients = client_source.text_search(params[:q], client_scope: client_search_scope)
    elsif current_user.can_use_strict_search?
      @clients = client_source.strict_search(strict_search_params, client_scope: client_search_scope)
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
      preload(preloads)

    @clients = @clients.page(params[:page]).per(20)

    if current_user.can_access_window_search? || current_user.can_access_client_search?
      sort_filter_index
    elsif current_user.can_use_strict_search?
      @client = client_source.new(strict_search_params)
      render 'strict_search'
    end
  end

  private def client_source
    GrdaWarehouse::Hud::Client
  end

  # should always return a destination client, but some visibility
  # is governed by the source client, some by the destination
  private def client_scope(id: nil)
    client_source.destination_client_viewable_by_user(client_id: id, user: current_user)
  end

  # Should always return any clients, source or destination that match
  def client_search_scope
    client_source.searchable_by(current_user)
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

  # Only allow a trusted parameter "white list" through.
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
