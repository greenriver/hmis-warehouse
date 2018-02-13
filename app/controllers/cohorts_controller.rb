class CohortsController < ApplicationController
  include PjaxModalController
  include CohortAuthorization
  before_action :some_cohort_access!
  before_action :require_can_manage_cohorts!, only: [:create, :destroy, :edit, :update]
  before_action :require_can_access_cohort!, only: [:show]
  before_action :set_cohort, only: [:edit, :update, :destroy, :show]

  def index
    @cohort = cohort_source.new
    @cohorts = cohort_scope
  end

  def show
    cohort_with_preloads = cohort_scope.where(id: cohort_id).
      preload(cohort_clients: [:cohort_client_notes, {client: :processed_service_history}])
    missing_document_state = @cohort.column_state.detect{|m| m.class == ::CohortColumns::MissingDocuments}
    @cohort = cohort_with_preloads.first
    
    if params[:inactive].present?
      @cohort_clients = @cohort.cohort_clients
    else
      @cohort_clients = @cohort.cohort_clients.where(active: true)
    end
  end

  def edit

  end

  def destroy
    @cohort.destroy
    redirect_to cohorts_path()
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
    cohort_options = cohort_params.except(:user_ids)
    user_ids = cohort_params[:user_ids].select(&:present?).map(&:to_i)
    @cohort.update(cohort_options)
    @cohort.update_access(user_ids)
    
    respond_with(@cohort, location: cohort_path(@cohort))
  end

  def cohort_params
    params.require(:grda_warehouse_cohort).permit(
      :name,
      :effective_date,
      :visible_state,
      :default_sort_direction,
      :only_window,
      user_ids: []
    )
  end

  def cohort_id
    params[:id].to_i
  end

  
  def flash_interpolation_options
    { resource_name: @cohort&.name }
  end
end
