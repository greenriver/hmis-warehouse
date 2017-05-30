class ClientsController < ApplicationController
  include PjaxModalController
  include ClientController
  include ArelHelper

  helper ClientMatchHelper

  before_action :require_can_view_clients!, only: [:show, :index, :month_of_service, :service_range, :history]
  before_action :require_can_view_clients_or_window!, only: [:rollup, :image]
  before_action :require_can_edit_clients!, only: [:edit, :merge, :unmerge, :update]
  before_action :set_client, only: [:show, :edit, :merge, :unmerge, :month_of_service, :service_range, :history, :rollup, :image, :chronic_days, :update]
  before_action :set_client_start_date, only: [:show, :edit, :history, :rollup]
  before_action :set_potential_matches, only: [:edit]
  after_action :log_client, only: [:show, :edit, :update, :destroy, :merge, :unmerge]

  helper_method :sort_column, :sort_direction

  def index
    # search
    @clients = if params[:q].present?
      client_source.text_search(params[:q])
    else
      client_scope
    end
    sort_filter_index()
    
  end

  def show
    log_item(@client)
    @note = GrdaWarehouse::ClientNotes::Base.new
  end

  def edit
    if params[:q].present?
      @search_clients = client_source.text_search(params[:q]).where.not(id: @client.id).limit(50)
    end
  end

  def update
    update_params = client_params
    update_params[:disability_verified_on] = if update_params[:disability_verified_on] == '1'
      @client.disability_verified_on || Time.now
    else
      nil
    end
    if update_params[:housing_release_status].present?
      update_params[:housing_assistance_network_released_on] = @client.housing_assistance_network_released_on || Time.now
    else
      update_params[:housing_assistance_network_released_on] = nil
    end
    if @client.update(update_params)
      flash[:notice] = 'Client updated'
      Cas::SyncToCasJob.perform_later
      redirect_to action: :show
    else
      flash[:notice] = 'Unable to update client'
      render :show
    end
  end

  def history
  end

  # display an assessment form in a modal
  def assessment
    @form = GrdaWarehouse::HmisForm.find(params.require(:id).to_i)
    render 'assessment_form'
  end

  # ajaxy method to render a particular rollup table
  def rollup
    allowed_rollups = [
      "/clients/rollup/assessments",
      "/clients/rollup/assessments_without_data",
      "/clients/rollup/case_manager",
      "/clients/rollup/chronic",
      "/clients/rollup/contact_information",
      "/clients/rollup/demographics",
      "/clients/rollup/disability_types",
      "/clients/rollup/entry_assessments",
      "/clients/rollup/error",
      "/clients/rollup/exit_assessments",
      "/clients/rollup/family",
      "/clients/rollup/income_benefits",
      "/clients/rollup/ongoing_residential_enrollments",
      "/clients/rollup/other_enrollments",
      "/clients/rollup/residential_enrollments",
      "/clients/rollup/services",
      "/clients/rollup/services_full",
      "/clients/rollup/special_populations",
      "/clients/rollup/zip_details",
      "/clients/rollup/zip_map",
      "/clients/rollup/client_notes",
    ]
    rollup = allowed_rollups.find do |m|
      m == "/clients/rollup/" + params.require(:partial).underscore
    end

    raise 'Rollup not in whitelist' unless rollup.present?

    begin
      render partial: rollup, layout: false
    end
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
    begin
      to_merge = client_params['merge'].reject(&:empty?)
      merged = []
      to_merge.each do |id|
        c = client_source.find(id)
        @client.merge_from c, reviewed_by: current_user, reviewed_at: DateTime.current
        merged << c
      end
      Importing::RunAddServiceHistoryJob.perform_later
      redirect_to({action: :edit}, notice: "Client records merged with #{merged.join(', ')}. Service history rebuild queued.")
    rescue ActiveRecord::ActiveRecordError => e
      Rails.logger.error e.inspect

      redirect_to({action: :edit}, alert: "Failed to merge client")
    end
  end

  # Un-merge clients
  # Remove warehouse_client entries listing un-merge clients as the source
  # Create new destination clients for each entry
  # Create new warehouse_clients to link source and destination
  # Queue update to service history
  def unmerge
    begin
      to_unmerge = client_params['unmerge'].reject(&:empty?)
      unmerged = []
      @dnd_warehouse_data_source = GrdaWarehouse::DataSource.destination.first
      # FIXME: Transaction kills this for some reason
      # GrdaWarehouse::Hud::Base.transaction do
        Rails.logger.info to_unmerge.inspect
        to_unmerge.each do |id|
          c = client_source.find(id)
          if c.warehouse_client_source.present?
            c.warehouse_client_source.delete
          end
          destination_client = c.dup
          destination_client.data_source = @dnd_warehouse_data_source
          destination_client.save
          GrdaWarehouse::WarehouseClient.create(id_in_source: c.PersonalID, source_id: c.id, destination_id: destination_client.id, data_source_id: c.data_source_id, proposed_at: Time.now, reviewed_at: Time.now, reviewd_by: current_user.id, approved_at: Time.now)
          unmerged << c.full_name
        # end
        Rails.logger.info '@client.invalidate_service_history'
        @client.invalidate_service_history
      end

      Importing::RunAddServiceHistoryJob.perform_later
      redirect_to({action: :edit}, notice: "Client records split from #{unmerged.join(', ')}. Service history rebuild queued.")
    rescue ActiveRecord::ActiveRecordError => e
      Rails.logger.error e.inspect

      redirect_to({action: :edit}, alert: "Failed to split clients")
    end
  end

  def month_of_service
    if params[:start].present?
      @start = params[:start].to_date
    else
      @start = @client.date_of_first_service.beginning_of_month
    end

    @days = @client.service_dates_for_display(@start)
    @programs = program_scope.preload(:organization).distinct.group_by{|m| [m.data_source_id, m.ProjectID]}
    # Prevent layout over ajax
    render layout: !request.xhr?
  end

  def service_range
    @range = @client.service_date_range
    respond_to do |format|
      format.json {
        render json: @range.map(&:to_s)
      }
    end
  end

  def chronic_days
    days = @client.
      chronics.
      where(date: 1.year.ago.to_date..Date.today).
      order(date: :asc).
      map do |c| 
        [c[:date], c[:days_in_last_three_years]]
      end.to_h
    respond_to do |format|
      format.json {
        render json: days
      }
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
    send_data @client.image(max_age), type: MimeMagic.by_magic(@client.image), disposition: 'inline'
  end

  private def client_scope
    client_source.destination
  end

  private def program_scope
    GrdaWarehouse::Hud::Project
  end

  private def service_history_service_scope
    GrdaWarehouse::ServiceHistory.service
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
        :disability_verified_on,
        :housing_assistance_network_released_on,
        :sync_with_cas,
        :dmh_eligible,
        :va_eligible,
        :hues_eligible,
        :hiv_positive,
        :housing_release_status,
        merge: [], 
        unmerge: []
      )
  end

  private def log_client
    log_item(@client)
  end

  private def dp(table, part, date)
    datepart table, part, date
  end
  helper_method :dp

end
