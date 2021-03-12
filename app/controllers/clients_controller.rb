###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ClientsController < ApplicationController
  include AjaxModalRails::Controller
  include ClientController
  include ClientShowPages
  include ArelHelper
  include ClientPathGenerator

  helper ClientMatchHelper
  helper ClientHelper

  before_action :require_can_access_some_client_search!, only: [:index, :simple]
  before_action :require_can_view_clients_or_window!, only: [:show, :service_range, :rollup, :image]
  before_action :require_can_view_enrollment_details_tab!, only: [:enrollment_details]
  before_action :require_can_see_this_client_demographics!, except: [:index, :new, :create, :simple, :appropriate]
  before_action :require_can_edit_clients!, only: [:edit, :merge, :unmerge]
  before_action :require_can_create_clients!, only: [:new, :create]
  before_action :set_client, only: [:show, :edit, :merge, :unmerge, :service_range, :rollup, :image, :chronic_days, :enrollment_details]
  before_action :set_search_client, only: [:simple, :appropriate]
  before_action :set_client_start_date, only: [:show, :edit, :rollup]
  before_action :set_potential_matches, only: [:edit]
  # This should no longer be needed
  # We can rely on searchable_by and viewable_by scopes on Client
  # before_action :check_release, only: [:show]
  after_action :log_client, only: [:show, :edit, :merge, :unmerge]

  helper_method :sort_column, :sort_direction

  def edit
    @search_clients = client_source.text_search(params[:q], client_scope: client_source).where.not(id: @client.id).limit(50) if params[:q].present?
  end

  # display an assessment form in a modal
  def assessment
    if can_view_clients?
      @form = assessment_scope.find(params.require(:id).to_i)
      @client = @form.client
    else
      client_id = params[:client_id].to_i
      @client = client_scope(id: client_id).find(client_id)
      if @client&.consent_form_valid?
        @form = assessment_scope.find(params.require(:id).to_i)
      else
        @form = assessment_scope.new
      end
    end
    render 'assessment_form'
  end

  def health_assessment
    if can_view_patients_for_own_agency?
      @form = health_assessment_scope.find(params.require(:id).to_i)
      @client = @form.client
    else
      @form = health_assessment_scope.new
    end
    render 'assessment_form'
  end

  # Merge clients into this client
  # If the client is a destination
  #   find its source clients
  #   if any of those source clients are included in to_merge, remove them from to_merge
  #   remove any warehouse_client entries listing those as the source
  #   create new warehouse_client entries with those as the source
  #     and this as the destination
  #   destination.invalidate_service_history
  #   delete the destination
  #
  # If the client is a source
  #   find it's destination
  #   remove any warehouse_client entries listing the client as the source
  #   create a new warehouse_client entry with the client as the source
  #     and this as the destination
  #   destination.invalidate_service_history
  #   if the destination doesn't have any more sources
  #     delete the destination
  #
  # invalidate service history for this
  # Queue update to service history
  def merge
    to_merge = client_params['merge'].reject(&:empty?)
    merged = []
    to_merge.each do |id|
      c = client_source.find(id)
      @client.merge_from c, reviewed_by: current_user, reviewed_at: DateTime.current
      merged << c
    end
    Importing::RunAddServiceHistoryJob.perform_later
    redirect_to({ action: :edit }, notice: "Client records merged with #{merged.map(&:name).join(', ')}. Service history rebuild queued.")
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error e.inspect

    redirect_to({ action: :edit }, alert: 'Failed to merge client')
  end

  # Un-merge clients
  # Remove warehouse_client entries listing un-merge clients as the source
  # Create new destination clients for each entry
  # Create new warehouse_clients to link source and destination
  # Queue update to service history
  def unmerge
    to_unmerge = client_params['unmerge'].reject(&:empty?)
    hmis_receiver = client_params['hmis_receiver']
    health_receiver = client_params['health_receiver']

    Rails.logger.info "Unmerging #{to_unmerge.inspect}"
    client_names = @client.split(to_unmerge, hmis_receiver, health_receiver, current_user)

    Rails.logger.info '@client.invalidate_service_history'
    @client.invalidate_service_history

    Importing::RunAddServiceHistoryJob.perform_later
    redirect_to({ action: :edit }, notice: "Client records split from #{client_names.join(', ')}. Service history rebuild queued.")
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error e.inspect

    redirect_to({ action: :edit }, alert: 'Failed to split clients')
  end

  def service_range
    @range = @client.service_date_range
    respond_to do |format|
      format.json do
        render json: @range.map(&:to_s)
      end
    end
  end

  # This is only valid for Potentially chronic (not HUD Chronic)
  def chronic_days
    days = @client.
      chronics.
      # where(date: 1.year.ago.to_date..Date.current).
      order(date: :asc).
      map do |c|
        [c[:date], c[:days_in_last_three_years]]
      end.to_h
    respond_to do |format|
      format.json do
        render json: days
      end
    end
  end

  protected def client_source
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
