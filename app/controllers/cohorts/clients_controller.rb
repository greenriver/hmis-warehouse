###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

require 'json/ext'
module Cohorts
  class ClientsController < ApplicationController
    include PjaxModalController
    include ArelHelper
    include Chronic
    include CohortAuthorization
    include CohortClients
    include ActionView::Helpers::TextHelper

    before_action :require_can_access_cohort!
    before_action :require_can_edit_cohort!, only: [:new, :create, :destroy]
    before_action :require_more_than_read_only_access_to_cohort!, only: [:edit, :update]
    before_action :require_can_manage_cohorts!, only: [:re_rank]
    before_action :set_cohort
    before_action :set_client, only: [:destroy, :update, :show, :pre_destroy, :field]
    before_action :load_cohort_names, only: [:index, :edit, :field, :update]
    skip_after_action :log_activity, only: [:index, :show]

    # Return a json object of {cohort_client.id : updated_at}
    # for easy poling
    def index
      # Never let the browser cache this response
      expires_now

      respond_to do |format|
        format.json do
          if params[:content].present?
            set_cohort_clients
            # Allow for individual refresh
            @cohort_clients = @cohort_clients.where(id: params[:cohort_client_id].to_i) if params[:cohort_client_id].present?
            render text: JSON.fast_generate(data_for_table), type: :json
            # The above is > 50% faster then
            # render json: data_for_table
          else
            render json: @cohort.cohort_clients.pluck(:id, :updated_at).map { |k, v| [k, v.to_i] }.to_h
          end
        end
        format.html do
          set_cohort_clients
          render layout: false
        end
      end
    end

    private def data_for_table
      data = []

      @visible_columns = [CohortColumns::Meta.new]
      @visible_columns += @cohort.visible_columns(user: current_user)
      @visible_columns << CohortColumns::Delete.new if current_user.can_manage_cohorts? || current_user.can_edit_cohort_clients?

      @cohort_clients.each do |cohort_client|
        client = cohort_client.client
        next if client.blank?

        row = {}
        @visible_columns.each do |cohort_column|
          cohort_column.cohort = @cohort
          cohort_column.cohort_names = @cohort_names

          # set the cohort_client we want this for this column
          # it will be used to render the corresponding cell
          cohort_column.cohort_client = cohort_client
          editable = cohort_column.display_as_editable?(current_user, cohort_client) && cohort_column.column_editable?
          row[cohort_column.column] = {
            value: cohort_column.display_read_only(current_user),
            # renderer: cohort_column.renderer,
            cohort_client_id: cohort_client.id,
            comments: cohort_column.comments,
            editable: editable,
          }
          row[cohort_column.column].merge!(cohort_column.metadata) if cohort_column.column == 'meta'
        end
        data << row
      end
      data
    end

    def edit
      @cohort_client = @cohort.cohort_clients.find(params[:id].to_i)
    end

    # Return the entire row of html layout false
    def show
      respond_to do |format|
        format.json do
          set_cohort_clients
          render json: @client.attributes.merge(updated_at_i: @client.updated_at.to_i)
        end
      end
    end

    # rubocop:disable Metrics/AbcSize
    def new
      @hoh_only = false
      @clients = client_scope.none
      @filter = ::Filters::Chronic.new(params[:filter])
      @hud_filter = ::Filters::HudChronic.new(params[:hud_filter])
      # whitelist for scope
      @populations = begin
        populations = populations_params[:population]&.map(&:to_sym)
        if populations
          populations.select { |e| GrdaWarehouse::ServiceHistoryEnrollment.know_standard_cohorts.include? e }
        elsif populations_params.key?('population')
          [:all_clients]
        else
          false
        end
      end
      @actives = actives_params
      @touchpoints = touch_point_params
      @client_ids = params[:batch].try(:[], :client_ids)

      @q = client_scope.none.ransack(params[:q])
      if params[:filter].present?
        @hoh_only = _debool(params[:filter][:hoh])
        load_filter
        @clients = @clients.includes(:chronics).
          preload(source_clients: :data_source).
          merge(GrdaWarehouse::Chronic.on_date(date: @filter.date)).
          order(LastName: :asc, FirstName: :asc)
      elsif params[:hud_filter].present?
        @hoh_only = _debool(params[:hud_filter][:hoh])
        load_hud_filter
        @clients = @clients.includes(:hud_chronics).
          preload(source_clients: :data_source).
          merge(GrdaWarehouse::HudChronic.on_date(date: @hud_filter.date)).
          order(LastName: :asc, FirstName: :asc)
      elsif @actives
        @hoh_only = _debool(@actives[:hoh])

        enrollment_scope = GrdaWarehouse::ServiceHistoryEnrollment.
          joins(:project).
          where(
            she_t[:client_id].eq(wcp_t[:client_id]),
          ).
          # homeless or overrides_homeless_active_status
          where(
            GrdaWarehouse::Hud::Project.project_type_override.in(GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES).
            or(p_t[:active_homeless_status_override].eq(true)),
          ).
          open_between(start_date: @actives[:start], end_date: @actives[:end])

        @clients = client_scope.joins(:processed_service_history).distinct
        if @actives[:limit_to_last_three_years] == '1'
          @clients = @clients.where(
            wcp_t[:days_homeless_last_three_years].gteq(@actives[:min_days_homeless]),
          )
        else
          @clients = @clients.where(wcp_t[:homeless_days].gteq(@actives[:min_days_homeless]))
        end

        if @actives.key? :actives_population
          populations = @actives[:actives_population]
          populations.each do |population|
            # Force service to fall within the correct age ranges for some populations
            service_scope = if ['youth', 'children'].include? population.to_s
              population
            elsif population.to_s == 'parenting_children'
              :children
            elsif population.to_s == 'parenting_youth'
              :youth
            elsif population.to_s == 'individual_adult'
              :adult
            else
              :current_scope
            end

            enrollment_scope = enrollment_scope.with_service_between(
              start_date: @actives[:start],
              end_date: @actives[:end],
              service_scope: service_scope,
            )

            enrollment_scope = enrollment_scope.send(population)
          end
        end
        # Active record seems to have trouble with the complicated nature of this scope
        @clients = @clients.where("EXISTS(#{enrollment_scope.to_sql})")
      elsif @populations
        @hoh_only = _debool(populations_params[:hoh])
        enrollment_query = GrdaWarehouse::ServiceHistoryEnrollment.
          homeless.
          ongoing.
          entry.
          where(she_t[:client_id].eq(c_t[:id])).select(c_t[:id])
        @populations.each do |population|
          service_scope = if ['youth', 'children'].include? population.to_s
            population
          elsif population.to_s == 'parenting_children'
            :children
          elsif population.to_s == 'parenting_youth'
            :youth
          else
            :current_scope
          end

          enrollment_query = enrollment_query.with_service_between(
            start_date: 3.months.ago.to_date,
            end_date: Date.current,
            service_scope: service_scope,
          )
          enrollment_query = enrollment_query.send(population)
        end
        @clients = client_scope.
          where(id: enrollment_query).distinct
      elsif @client_ids.present?
        @client_ids = @client_ids.strip.split(/\s+/).map { |m| m[/\d+/].to_i }
        @clients = client_scope.where(id: @client_ids)
      elsif params[:q].try(:[], :full_text_search).present?
        @q = client_source.ransack(params[:q])
        @clients = @q.result(distinct: true).merge(client_scope)
      elsif @touchpoints
        start_date = @touchpoints[:start].to_date
        end_date = @touchpoints[:end].to_date
        assessment_id = @touchpoints[:assessment_id].to_i
        candidate_ids = GrdaWarehouse::WarehouseClient.where(
          source_id: GrdaWarehouse::HmisForm.non_confidential.
            where(collected_at: (start_date..end_date),
                  assessment_id: assessment_id).distinct.select(:client_id),
        ).distinct.pluck(:destination_id)
        @clients = client_source.where(id: candidate_ids)
      end
      if @hoh_only
        @clients = @clients.joins(:service_history_enrollments).
          merge(GrdaWarehouse::ServiceHistoryEnrollment.heads_of_households).
          distinct
      end
      counts = GrdaWarehouse::WarehouseClientsProcessed.
        where(client_id: @clients.reorder(id: :asc).select(:id)).
        pluck(:client_id, :homeless_days, :days_homeless_last_three_years, :literally_homeless_last_three_years)
      @days_homeless = counts.map { |client_id, days_homeless, _, _| [client_id, days_homeless] }.to_h
      @days_homeless_three_years = counts.map { |client_id, _, days_homeless_last_three_years, _| [client_id, days_homeless_last_three_years] }.to_h
      @days_literally_homeless_three_years = counts.map { |client_id, _, _, literally_homeless_last_three_years| [client_id, literally_homeless_last_three_years] }.to_h
      Rails.logger.info "CLIENTS: #{@clients.to_sql}"
      @clients = @clients.where.not(id: @cohort.cohort_clients.select(:client_id)).pluck(*client_columns).map do |row|
        Hash[client_columns.zip(row)]
      end
      Rails.logger.info "CLIENTS: #{@clients.count}"
    end
    # rubocop:enable Metrics/AbcSize

    # Based on HudChronic#load_filter, but you can't include both Chronic and HudChronic as they define the same methods
    def load_hud_filter
      @hud_filter = ::Filters::HudChronic.new(params[:hud_filter])
      filter_query = hc_t[:age].gt(@hud_filter.min_age)
      filter_query = filter_query.and(hc_t[:individual].eq(@hud_filter.individual)) if @hud_filter.individual
      filter_query = filter_query.and(hc_t[:dmh].eq(@hud_filter.dmh)) if @hud_filter.dmh
      filter_query = filter_query.and(c_t[:VeteranStatus].eq(@hud_filter.veteran)) if @hud_filter.veteran
      @clients = client_source.joins(:hud_chronics).
        preload(:hud_chronics, :source_disabilities).
        where(filter_query).
        has_homeless_service_between_dates(start_date: (@hud_filter.date - @hud_filter.last_service_after.days), end_date: @hud_filter.date)
      @clients = @clients.text_search(@hud_filter.name, client_scope: GrdaWarehouse::Hud::Client.source) if @hud_filter.name&.present?
    end

    def load_cohort_names
      @cohort_names ||= cohort_source.pluck(:id, :name, :short_name). # rubocop:disable Naming/MemoizedInstanceVariableName
        map do |id, name, short_name|
        [id, short_name.presence || name]
      end.to_h
    end

    def client_columns
      @client_columns ||= [:id, :FirstName, :LastName, :DOB, :SSN, :Gender, :VeteranStatus]
    end

    def create
      client_ids = cohort_params[:client_ids]
      # Add all of the cohort clients quickly with no data
      incoming = client_ids.split(',').map(&:to_i)
      existing = cohort_client_source.with_deleted.where(cohort_id: @cohort.id).pluck(:client_id)
      needed = incoming - existing
      to_add = needed.map { |id| [id, @cohort.id, Time.now, Time.now] }
      cohort_client_source.new.insert_batch(
        cohort_client_source,
        [:client_id, :cohort_id, :created_at, :updated_at],
        to_add,
      )
      to_restore = incoming & cohort_client_source.only_deleted.where(cohort_id: @cohort.id).pluck(:client_id)
      cohort_client_source.only_deleted.where(cohort_id: @cohort.id, client_id: to_restore).update_all(deleted_at: nil)

      # Go back and get set the data for each client
      AddCohortClientsJob.perform_later(@cohort.id, client_ids, current_user.id)
      flash[:notice] = "#{pluralize(needed.count + to_restore.count, 'Client')} added to #{@cohort.name}; Some client data won't be available immediately, but will show up in a few minutes."
      respond_with(@cohort, location: cohort_path(@cohort))
    end

    def update
      update_params = cohort_update_params
      # Process the yes/no 1/0 submissions
      [:chronic, :vash_eligible, :sif_eligible, :veteran].each do |key|
        update_params[key] = _debool(update_params[key]) if update_params[key].present?
      end
      @client.assign_attributes(update_params)

      if @client.active_changed?
        if @client.active
          log_activate(@cohort.id, @client.id)
        else
          log_deactivate(@cohort.id, @client.id)
        end
      end

      if @client.save
        respond_to do |format|
          format.html do
            flash[:notice] = 'Saved'
            respond_with(@cohort, location: cohort_path(@cohort))
          end
          format.js do
            @response = {
              alert: :success,
              message: 'Saved',
              updated_at: @client.updated_at.to_i,
              cohort_client_id: @client.id,
            }
            render(json: @response)
            return
          end
          format.json do
            @response = {
              alert: :success,
              message: 'Saved',
              updated_at: @client.updated_at.to_i,
              cohort_client_id: @client.id,
            }
            render(json: @response)
            return
          end
        end
      else
        render json: { alert: :danger, message: 'Unable to save change' }
      end
    end

    def pre_destroy
    end

    def pre_bulk_destroy
      @cohort_client_ids = params.require(:cc).permit(:cohort_client_ids)[:cohort_client_ids].split(',')
    end

    def bulk_destroy
      @cohort_client_ids = params.require(:cc).permit(:cohort_client_ids)[:cohort_client_ids].split(',').map(&:to_i)
      @cohort_clients = cohort_client_source.where(id: @cohort_client_ids)
      removed = 0
      @cohort_clients.each do |client|
        log_removal(client.cohort_id, client.id, params[:cc].try(:[], :reason))
        removed += 1 if client.destroy
      end
      flash[:notice] = "Removed #{removed} #{'client'.pluralize(removed)}"
      redirect_to cohort_path(@cohort)
    end

    def re_rank
      new_order = params.require(:rank_order)&.split(',')&.map(&:to_i)
      new_order.each_with_index do |cohort_client_id, index|
        rank = index + 1
        @cohort.cohort_clients.find(cohort_client_id).update(rank: rank)
      end
      redirect_to cohort_path(@cohort)
    end

    def field
      column = GrdaWarehouse::Cohort.available_columns.map(&:class).map(&:name).select { |m| m == params.require(:field) }&.first
      if column.present?
        @cohort_client = @cohort.cohort_clients.find(params[:id].to_i)
        @column = column.constantize.new
        @column.cohort = @cohort
        @column.cohort_names = @cohort_names
        render layout: false
      else
        head :ok
      end
    end

    def destroy
      log_removal(@client.cohort_id, @client.id, params[:grda_warehouse_cohort_client].try(:[], :reason))
      if @client.destroy
        flash[:notice] = "Removed #{@client.name}"
        redirect_to cohort_path(@cohort)
      else
        render :pre_destroy
      end
    end

    def available_touchpoints
      GrdaWarehouse::HMIS::Assessment.
        active.
        non_confidential.
        for_user(current_user).
        order(:name).
        distinct.
        pluck(:name, :assessment_id)
    end
    helper_method :available_touchpoints

    def cohort_params
      params.require(:grda_warehouse_cohort).permit(
        :client_ids,
      )
    end

    def populations_params
      return {} unless params[:populations].present?

      params.require(:populations).permit(
        :hoh,
        population: [],
      )
    end

    def actives_params
      return false unless params[:actives].present?

      params.require(:actives).permit(
        :start,
        :end,
        :min_days_homeless,
        :limit_to_last_three_years,
        :hoh,
        actives_population: [],
      )
    end

    def touch_point_params
      return false unless params[:touchpoints].present?

      params.require(:touchpoints).permit(
        :start,
        :end,
        :assessment_id,
      )
    end

    def cohort_update_params
      params.require(:cohort_client).permit(*cohort_source.available_columns.select(&:column_editable?).map(&:column))
    end

    def log_create(cohort_id, cohort_client_id)
      attributes = {
        cohort_id: cohort_id,
        cohort_client_id: cohort_client_id,
        user_id: current_user.id,
        change: 'create',
        changed_at: Time.now,
      }
      cohort_client_changes_source.create(attributes)
    end

    def log_removal(cohort_id, cohort_client_id, reason)
      attributes = {
        cohort_id: cohort_id,
        cohort_client_id: cohort_client_id,
        user_id: current_user.id,
        change: 'destroy',
        changed_at: Time.now,
        reason: reason,
      }
      cohort_client_changes_source.create(attributes)
    end

    def log_activate(cohort_id, cohort_client_id)
      attributes = {
        cohort_id: cohort_id,
        cohort_client_id: cohort_client_id,
        user_id: current_user.id,
        change: 'activate',
        changed_at: Time.now,
      }
      cohort_client_changes_source.create(attributes)
    end

    def log_deactivate(cohort_id, cohort_client_id)
      attributes = {
        cohort_id: cohort_id,
        cohort_client_id: cohort_client_id,
        user_id: current_user.id,
        change: 'deactivate',
        changed_at: Time.now,
      }
      cohort_client_changes_source.create(attributes)
    end

    # only clients who have at least one source client
    # that is visible in the window
    # This is more strict than visible_in_window_to(user)
    def client_scope
      if @cohort.only_window
        client_source.destination.
          where(
            GrdaWarehouse::WarehouseClient.joins(:data_source).
            where(ds_t[:visible_in_window].eq(true)).
            where(wc_t[:destination_id].eq(c_t[:id])).
            exists,
          )
      else
        client_source.destination
      end
    end

    def client_source
      GrdaWarehouse::Hud::Client
    end

    def set_client
      @client = @cohort.cohort_clients.find(params[:id].to_i)
    end

    def cohort_client_source
      GrdaWarehouse::CohortClient
    end

    def cohort_client_changes_source
      GrdaWarehouse::CohortClientChange
    end

    def cohort_id
      params[:cohort_id].to_i
    end

    def flash_interpolation_options
      { resource_name: @cohort.name }
    end

    private def _debool(bool_str)
      case bool_str
      when true, 'yes', 'true', '1' then true
      else
        false
      end
    end
  end
end
