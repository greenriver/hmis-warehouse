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
      cohort_params[:client_ids].split(',').map(&:strip).compact.each do |id|
        @cohort.cohort_clients.build(client_id: id)
      end
      @cohort.save
      respond_with(@cohort, location: cohort_path(@cohort))
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