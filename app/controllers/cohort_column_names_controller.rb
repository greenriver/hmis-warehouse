###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CohortColumnNamesController < ApplicationController
  before_action :require_can_configure_cohorts!
  before_action :set_columns

  def new
  end

  def create
    update_columns(params[:cohort_column]) if params.include? :cohort_column

    redirect_to new_cohort_column_name_url
  end

  def update_columns(cohort_columns)
    columns = cohort_source.available_columns

    columns.each do |column|
      next unless column.attributes.include?(:translation_key)

      proposed_translation = cohort_columns[column.column]
      key = column.translation_key
      translation = Translation.where(key: key).first_or_create
      translation.update(text: proposed_translation)
      Translation.invalidate_translation_cache(key) # force re-calculation
    end

    columns.each do |column|
      next unless column.attributes.include?(:description_translation_key)

      proposed_translation = cohort_columns["#{column.column}_description"].presence
      key = column.description_translation_key
      translation = Translation.where(key: key).first_or_create
      translation.update(text: proposed_translation)
      Translation.invalidate_translation_cache(key) # force re-calculation
    end

    columns.each do |column|
      # if the column is not active, and the active checkbox is checked, activate the column
      column.column_type.activate if ! column.column_type.active? && cohort_columns["#{column.column}_active"] == '1'
      # if the column is active, and the active checkbox is unchecked, deactivate the column
      column.column_type.deactivate if column.column_type.active? && cohort_columns["#{column.column}_active"] == '0'
    end
  end

  def column_type(column)
    case column.input_type
    when 'integer'
      'Number'
    when 'boolean'
      'Check box'
    when 'select2'
      'Option List'
    when 'date_picker'
      'Date'
    else
      column.input_type.humanize
    end
  end
  helper_method :column_type

  def set_columns
    @columns = cohort_source.available_columns
  end

  def cohort_source
    GrdaWarehouse::Cohort
  end
end
