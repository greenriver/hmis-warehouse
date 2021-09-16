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

  before_action :require_can_access_some_client_search!, only: [:simple]
  before_action :require_can_view_clients!, only: [:show, :service_range, :rollup, :image, :assessment]
  before_action :require_can_view_enrollment_details_tab!, only: [:enrollment_details]
  before_action :require_can_see_this_client_demographics!, except: [:new, :create, :simple, :appropriate, :assessment, :health_assessment]
  before_action :require_can_edit_clients!, only: [:edit, :merge, :unmerge]
  before_action :require_can_create_clients!, only: [:new, :create]
  before_action :set_client, only: [:show, :edit, :merge, :unmerge, :service_range, :rollup, :image, :chronic_days, :enrollment_details]
  before_action :set_search_client, only: [:simple, :appropriate]
  before_action :set_client_start_date, only: [:show, :edit, :rollup]
  before_action :set_potential_matches, only: [:edit]
  after_action :log_client, only: [:show, :edit, :merge, :unmerge]

  helper_method :sort_column, :sort_direction

  def create
    clean_params = client_create_params
    clean_params[:SSN] = clean_params[:SSN]&.gsub(/\D/, '')
    existing_matches = look_for_existing_match(clean_params)
    @bypass_search = false
    # If we only have one authoritative data source, we don't bother sending it, just use it
    clean_params[:data_source_id] ||= GrdaWarehouse::DataSource.authoritative.first.id if GrdaWarehouse::DataSource.authoritative.count == 1
    # Handle multi gender
    clean_params[:Gender]&.each do |k|
      next if k.blank?

      gender_column = HUD.gender_id_to_field_name[k.to_i]
      clean_params[gender_column] = 1
    end
    clean_params.delete(:Gender)
    @client = client_source.new(clean_params)

    params_valid = validate_new_client_params(clean_params)

    @existing_matches ||= []
    if ! params_valid
      flash[:error] = 'Unable to create client'
      render action: :new
    elsif existing_matches.any? && ! clean_params[:bypass_search].present?
      # Show the new page with the option to go to an existing client
      # add bypass_search as a hidden field so we don't end up here again
      # raise @existing_matches.inspect
      @bypass_search = true
      @existing_matches = client_source.where(id: existing_matches).
        joins(:warehouse_client_source).
        includes(:warehouse_client_source, :data_source)
      render action: :new
    elsif clean_params[:bypass_search].present? || existing_matches.empty?
      # Create a new source and destination client
      # and redirect to the new client show page
      client_source.transaction do
        destination_ds_id = GrdaWarehouse::DataSource.destination.first.id
        @client.save
        @client.update(PersonalID: @client.id)

        destination_client = client_source.new(clean_params.
          merge(
            data_source_id: destination_ds_id,
            PersonalID: @client.id,
            creator_id: current_user.id,
          ))
        destination_client.send_notifications = true
        destination_client.save

        warehouse_client = GrdaWarehouse::WarehouseClient.create(
          id_in_source: @client.id,
          source_id: @client.id,
          destination_id: destination_client.id,
          data_source_id: @client.data_source_id,
        )
        if @client.persisted? && destination_client.persisted? && warehouse_client.persisted?
          flash[:notice] = "Client #{@client.full_name} created."
          after_create_path = client_path_generator
          if @client.data_source.after_create_path.present?
            after_create_path += [@client.data_source.after_create_path]
            redirect_to polymorphic_path(after_create_path, client_id: destination_client.id)
          else
            redirect_to polymorphic_path(after_create_path, id: destination_client.id)
          end
        else
          flash[:error] = 'Unable to create client'
          render action: :new
        end
      end
    end
  end

  def edit
    @search_clients = client_source.text_search(params[:q], client_scope: client_source).where.not(id: @client.id).limit(50) if params[:q].present?
  end

  # display an assessment form in a modal
  def assessment
    form = assessment_scope.find(params.require(:id).to_i)
    client = form.client&.destination_client
    if client&.show_demographics_to?(current_user)
      @form = form
      @client = client
    else
      @form = assessment_scope.new
    end
    render 'assessment_form'
  end

  def health_assessment
    form = health_assessment_scope.find(params.require(:id).to_i)
    client = form.client&.destination_client
    patient = client&.patient
    if patient&.visible_to(current_user)
      @form = form
      @client = client
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
    GrdaWarehouse::Tasks::ServiceHistory::Add.new(force_sequential_processing: true).run!
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

    GrdaWarehouse::Tasks::ServiceHistory::Add.new(force_sequential_processing: true).run!
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

  private def client_scope(id: nil)
    source_client_ids = nil
    source_client_ids = GrdaWarehouse::WarehouseClient.where(destination_id: id).pluck(:source_id) if id
    client_source.destination_visible_to(current_user, source_client_ids: source_client_ids).where(id: id)
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
