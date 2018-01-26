class CohortsController < ApplicationController
  include PjaxModalController
  helper CohortColumnsHelper
  before_action :require_can_view_cohorts!
  before_action :set_cohort, only: [:edit, :update, :destroy]

  def index
    @cohort = cohort_source.new
    @cohorts = cohort_source.viewable_by(current_user)
  end

  def show
    @cohort = cohort_source.where(id: params[:id].to_i).preload(cohort_clients: [:cohort_client_notes, :client]).first
    @rank_column = @cohort.visible_columns.find{|c| c.column == 'rank'}
    @first_name_column = @cohort.visible_columns.find{|c| c.column == 'first_name'}
    @last_name_column = @cohort.visible_columns.find{|c| c.column == 'last_name'}
    @frozen_column_count = (
      (@rank_column.nil? ? 0 : 1) + (@first_name_column.nil? ? 0 : 1) + (@last_name_column.nil? ? 0 : 1)
    )
    @visible_columns = @cohort.visible_columns - [@rank_column, @first_name_column, @last_name_column]
    @input_column_indexes = @visible_columns.each_with_index.map do |c,i| 
      next if c.input_type == 'read_only'
      # account for the note columns
      if i > @frozen_column_count
        i + 2
      else
        i
      end
    end.compact
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
