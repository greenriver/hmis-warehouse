###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CohortColumnOptionsController < ApplicationController
  include CohortAuthorization
  before_action :require_can_configure_cohorts!
  before_action :set_cohort_column_option, only: [:edit, :update, :destroy]
  before_action :set_cohort_column_options, only: [:index, :create]

  def index
    @cohort_column_options = @cohort_column_options.order(cohort_column: :desc, value: :asc)
  end

  # Fetch values for columns that are in use in a performant way
  private def cohort_column_options_in_use
    @cohort_column_options_in_use ||= begin
      cohort_columns = GrdaWarehouse::CohortColumnOption.new.cohort_columns
      column_names = cohort_columns.map(&:column)
      found = {}
      sub_queries = column_names.map do |column_name|
        found[column_name] = []
        quoted_column = GrdaWarehouse::CohortClient.connection.quote_column_name(column_name.to_s)

        GrdaWarehouse::CohortClient.
          select(Arel.sql("'#{column_name}' AS cohort_column, #{quoted_column} AS value")).
          where.not(column_name => [nil, '']).
          distinct
      end

      # Generate the SQL for each sub-query and join them with UNION ALL.
      sql = sub_queries.map(&:to_sql).join(' UNION ALL ')

      result = GrdaWarehouse::CohortClient.connection.execute(sql)

      result.each do |row|
        found[row['cohort_column']] << row['value']
      end

      found
    end
  end
  helper_method :cohort_column_options_in_use

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

  def destroy
    if cohort_column_options_in_use[@cohort_column_option.cohort_column]&.exclude?(@cohort_column_option.value)
      @cohort_column_option.destroy
      Rails.cache.delete("available_options_for_#{@cohort_column_option.cohort_column}")
      respond_with(@cohort_column_option, location: cohort_column_options_path)
    else
      flash[:error] = "The option: #{@cohort_column_option.value} is in use and cannot be deleted."
      redirect_to cohort_column_options_path
    end
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
