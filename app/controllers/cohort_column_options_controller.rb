###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class CohortColumnOptionsController < ApplicationController
  include CohortAuthorization
  before_action :require_can_manage_cohorts!
  before_action :set_cohort_column_option, only: [:edit, :update]
  before_action :set_cohort_column_options, only: [:index, :create]

  def index
    @cohort_column_options = @cohort_column_options.order(cohort_column: :desc, value: :asc)
    @cohort_column_options_in_use = GrdaWarehouse::CohortColumnOption.new.cohort_columns.map do |cohort_column|
      [
        cohort_column.column,
        GrdaWarehouse::CohortClient.where.not(cohort_column.column => nil).distinct.pluck(cohort_column.column),
      ]
    end.to_h
  end

  def new
    @cohort_column_option = cohort_column_option_source.new
  end

  def create
    @cohort_column_option = cohort_column_option_source.create(cohort_column_option_params)
    Rails.cache.delete("available_options_for_#{@cohort_column_option.cohort_column}")
    respond_with(@cohort_column_option, location: cohort_column_options_path)
  end

  def edit
  end

  def update
    @cohort_column_option.update(cohort_column_option_params)
    Rails.cache.delete("available_options_for_#{@cohort_column_option.cohort_column}")
    respond_with(@cohort_column_option, location: cohort_column_options_path)
  end

  def set_cohort_column_option
    @cohort_column_option = cohort_column_option_source.find(params[:id].to_i)
  end

  def set_cohort_column_options
    @cohort_column_options = cohort_column_option_source.all
  end

  def cohort_column_option_source
    GrdaWarehouse::CohortColumnOption
  end

  def flash_interpolation_options
    { resource_name: 'Cohort Column Option' }
  end

  private

  def cohort_column_option_params
    params.require(:grda_warehouse_cohort_column_option).permit(
      :cohort_column,
      :value,
      :weight,
      :active,
    )
  end
end
