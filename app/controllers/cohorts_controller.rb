class CohortsController < ApplicationController
  include PjaxModalController
  before_action :require_can_view_cohorts!
  before_action :set_cohort, only: [:edit, :update, :destroy]

  def index
    @cohort = cohort_source.new
    @cohorts = cohort_source.viewable_by(current_user)
  end

  def show
    @cohort = cohort_source.where(id: params[:id].to_i).preload(cohort_clients: [:cohort_client_notes, :client]).first
  end

  def edit

  end

  def destroy

  end

  def create
    begin
      @cohort = cohort_source.create!(cohort_params)
      respond_with(@cohort, location: cohort_path(@cohort))
    rescue Exception => e
      flash[:error] = e.message
      redirect_to cohorts_path()
    end
  end

  def update
    @cohort.update(cohort_params)
    respond_with(@cohort, location: cohort_path(@cohort))
  end

  def cohort_params
    params.require(:grda_warehouse_cohort).permit(
      :name,
      :effective_date,
      :visible_state,
    )
  end

  def set_cohort
    @cohort = cohort_source.find(params[:id].to_i)
  end

  def cohort_source
    GrdaWarehouse::Cohort
  end

  def flash_interpolation_options
    { resource_name: @cohort&.name }
  end
end
