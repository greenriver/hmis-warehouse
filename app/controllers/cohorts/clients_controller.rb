module Cohorts
  class ClientsController < ApplicationController
    include PjaxModalController
    include ArelHelper
    include Chronic
    before_action :require_can_create_cohorts!
    before_action :set_cohort
    before_action :set_client, only: [:destroy, :update, :show]
    skip_after_action :log_activity, only: [:index, :show]

    # Return a json object of {cohort_client.id : updated_at}
    # for easy poling
    def index
      respond_to do |format|
        format.json do
          render json: @cohort.cohort_clients.pluck(:id, :updated_at).map{|k,v| [k, v.to_i]}.to_h
        end
      end
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
      @clients = []
      @filter = ::Filters::Chronic.new(params[:filter])
      @q = client_scope.none.ransack(params[:q])
      if params[:filter].present?
        load_filter()
        @clients = @clients.includes(:chronics).
          preload(source_clients: :data_source).
          merge(GrdaWarehouse::Chronic.on_date(date: @filter.date)).
          order(LastName: :asc, FirstName: :asc)
      elsif params[:q].try(:[], :full_text_search).present?
        @q = client_scope.ransack(params[:q])
        @clients = @q.result(distinct: true)
      end
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
      update_params['chronic'] = _debool(update_params['chronic'])
      update_params['vash_eligible'] = _debool(update_params['vash_eligible'])
      update_params['sif_eligible'] = _debool(update_params['sif_eligible'])
      update_params['veteran'] = _debool(update_params['veteran'])
      if @client.update(update_params)
        respond_to do |format|
          format.html do
            flash[:notice] = 'Saved'
            respond_with(@cohort, location: cohort_path(@cohort))
          end
          format.js do
            @response = OpenStruct.new({alert: :success, message: 'Saved'})
          end
          format.json do
            @response = OpenStruct.new({alert: :success, message: 'Saved'})
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
      ch.save if ch.changed? || ch.new_record?
    end

    def destroy
      @client.destroy
      respond_with(@cohort, location: cohort_path(@cohort))
    end

    def cohort_params
      params.require(:grda_warehouse_cohort).permit(
        :client_ids
      )
    end

    def cohort_update_params
      params.require(:grda_warehouse_cohort_client).permit(*cohort_source.available_columns.map(&:column))
    end

    def client_scope
      client_source
    end

    def client_source
      GrdaWarehouse::Hud::Client
    end

    def set_client
      @client = cohort_client_source.find(params[:id].to_i)
    end

    def cohort_client_source
      GrdaWarehouse::CohortClient
    end

    def set_cohort
      @cohort = cohort_source.find(params[:cohort_id].to_i)
    end
  
    def cohort_source
      GrdaWarehouse::Cohort
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
