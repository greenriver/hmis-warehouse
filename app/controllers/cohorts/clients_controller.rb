module Cohorts
  class ClientsController < ApplicationController
    include PjaxModalController
    before_action :require_can_create_cohorts!
    before_action :set_cohort
    before_action :set_client, only: [:destroy]

    def new
      @column_state = @cohort.column_state || cohort_source.available_columns
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

    def create_cohort_client(cohort_id, client_id)
      ch = cohort_client_source.with_deleted.
        where(cohort_id: cohort_id, client_id: client_id).first_or_initialize
      ch.deleted_at = nil
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
  end
end