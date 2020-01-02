###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class ClientsController < ApplicationController
  include PjaxModalController
  include ClientController
  include ArelHelper
  include ClientPathGenerator

  helper ClientMatchHelper
  helper ClientHelper

  before_action :require_can_view_or_search_clients_or_window!, only: [:index]
  before_action :require_can_view_clients_or_window!, only: [:show, :service_range, :rollup, :image]

  before_action :require_can_see_this_client_demographics!, except: [:index, :new, :create]
  before_action :require_can_edit_clients!, only: [:edit, :merge, :unmerge]
  before_action :require_can_create_clients!, only: [:new, :create]
  before_action :set_client, only: [:show, :edit, :merge, :unmerge, :service_range, :rollup, :image, :chronic_days]
  before_action :set_client_start_date, only: [:show, :edit, :rollup]
  before_action :set_potential_matches, only: [:edit]
  # This should no longer be needed
  # We can rely on searchable_by and viewable_by scopes on Client
  before_action :check_release, only: [:show]
  after_action :log_client, only: [:show, :edit, :merge, :unmerge]

  helper_method :sort_column, :sort_direction

  def index
    @show_ssn = GrdaWarehouse::Config.get(:show_partial_ssn_in_window_search_results) || can_view_full_ssn?
    # search
    @clients = if params[:q].present?
      client_source.text_search(params[:q], client_scope: client_search_scope)
    else
      client_scope.none
    end
    @clients = @clients.preload(:processed_service_history)
    sort_filter_index
  end

  def show
    log_item(@client)
    @note = GrdaWarehouse::ClientNotes::Base.new
  end

  def edit
    @search_clients = client_source.text_search(params[:q], client_scope: client_source).where.not(id: @client.id).limit(50) if params[:q].present?
  end

  # display an assessment form in a modal
  def assessment
    if can_view_clients?
      @form = assessment_scope.find(params.require(:id).to_i)
      @client = @form.client
    else
      @client = client_scope(id: params[:client_id].to_i).find(params[:client_id].to_i)
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
    unmerged = []
    @dnd_warehouse_data_source = GrdaWarehouse::DataSource.destination.first
    # FIXME: Transaction kills this for some reason
    # GrdaWarehouse::Hud::Base.transaction do
    Rails.logger.info "Unmerging #{to_unmerge.inspect}"
    to_unmerge.each do |id|
      c = client_source.find(id)
      c.warehouse_client_source.destroy if c.warehouse_client_source.present?
      destination_client = c.dup
      destination_client.data_source = @dnd_warehouse_data_source
      destination_client.save

      receive_hmis = hmis_receiver == id
      receive_health = health_receiver == id
      GrdaWarehouse::ClientSplitHistory.create(
        split_from: @client.id,
        split_into: destination_client.id,
        receive_hmis: receive_hmis,
        receive_health: receive_health,
      )

      GrdaWarehouse::WarehouseClient.create(id_in_source: c.PersonalID, source_id: c.id, destination_id: destination_client.id, data_source_id: c.data_source_id, proposed_at: Time.now, reviewed_at: Time.now, reviewd_by: current_user.id, approved_at: Time.now)

      destination_client.move_dependent_hmis_items(@client.id, destination_client.id) if receive_hmis
      destination_client.move_dependent_health_items(@client.id, destination_client.id) if receive_health

      unmerged << c.full_name
    end
    Rails.logger.info '@client.invalidate_service_history'
    @client.invalidate_service_history
    # end

    Importing::RunAddServiceHistoryJob.perform_later
    redirect_to({ action: :edit }, notice: "Client records split from #{unmerged.join(', ')}. Service history rebuild queued.")
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
      send_data image, type: MimeMagic.by_magic(image), disposition: 'inline'
    else
      head(:forbidden)
      nil
    end
  end

  protected def client_source
    GrdaWarehouse::Hud::Client
  end

  # should always return a destination client, but some visibility
  # is governed by the source client, some by the destination
  private def client_scope(id: nil)
    client_source.destination.where(
      Arel.sql(
        client_source.arel_table[:id].in(visble_by_source(id: id)).
        or(client_source.arel_table[:id].in(visible_by_destination(id: id))).to_sql,
      ),
    )
  end

  private def visble_by_source(id: nil)
    query = GrdaWarehouse::WarehouseClient.joins(:source).
      merge(GrdaWarehouse::Hud::Client.viewable_by(current_user))
    query = query.where(destination_id: id) if id.present?

    Arel.sql(query.select(:destination_id).to_sql)
  end

  private def visible_by_destination(id: nil)
    query = GrdaWarehouse::Hud::Client.viewable_by(current_user)
    query = query.where(id: id) if id.present?

    Arel.sql(query.select(:id).to_sql)
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
