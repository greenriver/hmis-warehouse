###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class CohortColumnNamesController < ApplicationController
  before_action :require_can_manage_cohorts!
  before_action :set_columns

  def new
  end

  def create
    translate_columns(params[:translation]) if params.include? :translation

    redirect_to new_cohort_column_name_url
  end

  def translate_columns(translations)
    columns = cohort_source.available_columns
    locale = 'en'
    columns.each do |column|
      next unless column.attributes.include?(:translation_key)

      proposed_translation = translations[column.column]
      key = column.translation_key
      translation_key = TranslationKey.find_or_create_by(key: key)
      existing_translation = translation_key.translations.where(locale: locale).first_or_create do |translation|
        translation.text = proposed_translation
      end
      existing_translation.update_attribute(:text, proposed_translation) if existing_translation != proposed_translation
      FastGettext.expire_cache_for(key)
      Rails.cache.write('translation-fresh-at', Time.current)
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
