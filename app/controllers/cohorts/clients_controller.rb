module Cohorts
  class ClientsController < ApplicationController
    include PjaxModalController
    include ArelHelper
    include Chronic
    include CohortAuthorization


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
      respond_to do |format|
        format.json do
          if params[:content].present?
            if params[:inactive].present?
              @cohort_clients = @cohort.cohort_clients
            else
              @cohort_clients = @cohort.cohort_clients.where(active: true)
            end
                      
            @cohort_clients = @cohort_clients.
              preload(:cohort_client_notes, client: :processed_service_history).
              page(params[:page].to_i).per(params[:per].to_i)

            render json: data_for_table() and return
          else
            render json: @cohort.cohort_clients.pluck(:id, :updated_at).map{|k,v| [k, v.to_i]}.to_h
          end
        end
        format.html do
          if params[:inactive].present?
            @cohort_clients = @cohort.cohort_clients
          else
            @cohort_clients = @cohort.cohort_clients.where(active: true)
          end
                    
          @cohort_clients = @cohort_clients.page(params[:page].to_i).per(params[:per].to_i)
          render layout: false
        end
      end
    end

    def data_for_table
      data = []
      expires = if Rails.env.development? 
        1.minute 
      else 
        8.hours 
      end

      @cohort_clients.each do |cohort_client|
        client = cohort_client.client
        cohort_client_data = Rails.cache.fetch(['cohort_clients', @cohort, cohort_client, client, cohort_client.cohort_client_notes.length, current_user.can_view_clients?, params], expires_in: expires) do
          @visible_columns = [CohortColumns::Meta.new]
          cohort_client_data = {}
          @visible_columns += @cohort.visible_columns
          if current_user.can_manage_cohorts? || current_user.can_edit_cohort_clients?
            @visible_columns << CohortColumns::Delete.new
          end
          @visible_columns.each do |cohort_column|
            cohort_column.cohort = @cohort
            cohort_column.cohort_names = @cohort_names
            cohort_column.cohort_client = cohort_client
            editable = cohort_column.display_as_editable?(current_user, cohort_client) && cohort_column.column_editable?
            cohort_client_data[cohort_column.column] = {
              editable: editable, 
              value: cohort_column.display_read_only(current_user), 
              renderer: cohort_column.renderer,
              cohort_client_id: cohort_client.id,
            }

            if cohort_column.column == 'meta'
              cohort_client_data[cohort_column.column].merge!(cohort_column.metadata)
            end
          end
          cohort_client_data
        end
      
        data << cohort_client_data
      end
      return data
    end

    def edit
      @cohort_client = @cohort.cohort_clients.find(params[:id].to_i)
    end

    # Return the entire row of html layout false
    def show
      respond_to do |format|
        format.json do
          render json: @client.attributes.merge(updated_at_i: @client.updated_at.to_i)
        end
      end
    end

    def new
      @clients = client_scope.none
      @filter = ::Filters::Chronic.new(params[:filter])
      @population = params[:population]
      @actives = actives_params()

      @q = client_scope.none.ransack(params[:q])
      if params[:filter].present?
        load_filter()
        @clients = @clients.includes(:chronics).
          preload(source_clients: :data_source).
          merge(GrdaWarehouse::Chronic.on_date(date: @filter.date)).
          order(LastName: :asc, FirstName: :asc)
      elsif @population
        # Force service to fall within the correct age ranges for some populations
        service_scope = :current_scope
        if ['youth', 'children'].include? @population 
          service_scope = @population
        elsif @population == 'parenting_children'
          service_scope = :children
        elsif @population == 'parenting_youth'
          service_scope = :youth
        end
        # we have to hack this because Active Records gets confused with the binds
        # using to_sql forces binding the options one at a time
        # https://github.com/rails/rails/issues/20077
        enrollment_exists = GrdaWarehouse::ServiceHistoryEnrollment.
            homeless.
            ongoing.
            entry.
            with_service_between(start_date: 3.months.ago.to_date, end_date: Date.today, service_scope: service_scope).
            where(she_t[:client_id].eq(c_t[:id])).
            send(@population).
            to_sql
        @clients = client_scope.
          where("EXISTS (#{enrollment_exists})").distinct
      elsif @actives
        @clients = client_scope.joins(:processed_service_history).
          where(
            GrdaWarehouse::ServiceHistoryEnrollment.where(
              she_t[:client_id].eq(wcp_t[:client_id])
            ).homeless.open_between(start_date: @actives[:start], end_date: @actives[:end]).
            exists
          ).
          where(wcp_t[:homeless_days].gteq(@actives[:min_days_homeless])).
          distinct

      elsif params[:q].try(:[], :full_text_search).present?
        @q = client_source.ransack(params[:q])
        @clients = @q.result(distinct: true).merge(client_scope)
      end
      @days_homeless = GrdaWarehouse::WarehouseClientsProcessed.
        where(client_id: @clients.select(:id)).
        pluck(:client_id, :homeless_days).to_h
      @clients = @clients.pluck(*client_columns).map do |row|
        Hash[client_columns.zip(row)]
      end
    end

    def load_cohort_names
      @cohort_names = cohort_source.pluck(:id, :name, :short_name).
      map do |id, name, short_name|
        [id, short_name.presence || name]
      end.to_h
    end

    def client_columns
      @client_columns ||= [:id, :FirstName, :LastName, :DOB, :SSN, :Gender, :VeteranStatus]
    end

    def create
      if cohort_params[:client_ids].present?
        cohort_params[:client_ids].split(',').map(&:strip).compact.each do |id|
          create_cohort_client(@cohort.id, id.to_i)
        end
      elsif cohort_params[:client_id].present?
        create_cohort_client(@cohort.id, cohort_params[:client_id].to_i)
      end
      flash[:notice] = "Clients updated for #{@cohort.name}"
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
            render json: @response and return
          end
          format.json do
            @response = {
              alert: :success, 
              message: 'Saved', 
              updated_at: @client.updated_at.to_i, 
              cohort_client_id: @client.id,
            }
            render json: @response and return
          end
        end        
      else
        render json: {alert: :danger, message: 'Unable to save change'}
      end
    end

    def create_cohort_client(cohort_id, client_id)
      ch = cohort_client_source.with_deleted.
        where(cohort_id: cohort_id, client_id: client_id).first_or_initialize
      ch.deleted_at = nil
      cohort_source.available_columns.each do |column|
        if column.has_default_value?
          ch[column.column] = column.default_value(client_id)
        end
      end
      if ch.changed? || ch.new_record?
        ch.save
        log_create(cohort_id, ch.id)
      end
    end

    def pre_destroy

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
      column = GrdaWarehouse::Cohort.available_columns.map(&:class).map(&:name).select{|m| m == params.require(:field)}&.first
      if column.present?
        @cohort_client = @cohort.cohort_clients.find(params[:id].to_i)
        @column = column.constantize.new()
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

    def cohort_params
      params.require(:grda_warehouse_cohort).permit(
        :client_ids
      )
    end

    def actives_params
      return unless params[:actives].present?
      params.require(:actives).permit(
        :start,
        :end,
        :min_days_homeless,
      )
    end

    def cohort_update_params
      params.require(:cohort_client).permit(*cohort_source.available_columns.map(&:column))
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
    def client_scope
      if @cohort.only_window
        client_source.destination.
          where(
            GrdaWarehouse::WarehouseClient.joins(:data_source). 
            where(ds_t[:visible_in_window].eq(true)).
            where(wc_t[:destination_id].eq(c_t[:id])).
            exists 
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
      when true, "yes", "true", "1" then true
      else
        false
      end
    end

  end
end
