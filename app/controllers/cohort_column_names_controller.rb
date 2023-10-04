###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class CohortColumnNamesController < ApplicationController
  before_action :require_can_configure_cohorts!
  before_action :set_columns

  def new
  end

  def create
    translate_columns(params[:translation]) if params.include? :translation

    redirect_to new_cohort_column_name_url
  end

  def translate_columns(translations)
    columns = cohort_source.available_columns
    columns.each do |column|
      next unless column.attributes.include?(:translation_key)

      proposed_translation = translations[column.column]
      key = column.translation_key
      translation = Translation.where(key: key).first_or_create
      translation.update(text: proposed_translation)
      Translation.invalidate_translation_cache(key) # force re-calculation
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
