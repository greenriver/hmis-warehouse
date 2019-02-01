module Cohorts
  class ColumnsController < ApplicationController
    include PjaxModalController
    before_action :require_can_manage_cohorts!
    before_action :set_cohort

    def edit
      @column_state = @cohort.column_state&.presence || cohort_source.default_visible_columns
    end

    def update
      columns = cohort_source.available_columns.deep_dup
      if params.include? :order
        order = params[:order].split(',')
        columns = columns.sort_by{ |col| order.index(col.column.to_s)}
      end
      columns.each do |column|
        visibility_state = cohort_params[:visible][column.column]
        column.visible = false 
        if visibility_state.present? || visibility_state.to_s == '1'
          column.visible = true
        end

        editability_state = cohort_params[:editable][column.column] rescue nil
        column.editable = false 
        if editability_state.present? || editability_state.to_s == '1'
          column.editable = true
        end
      end
      @cohort.update(column_state: columns)
      if params.include? :translation
        translate_columns(params[:translation])
      end
      respond_with(@cohort, location: cohort_path(@cohort))
    end

    def translate_columns(translations)
      return unless can_edit_translations?

      columns = cohort_source.available_columns
      locale = 'en'
      columns.each do |column|
        if column.attributes.include?(:translation_key)
          proposed_translation = translations[column.column]
          key = column.translation_key
          translation_key = TranslationKey.find_or_create_by(key: key)
          existing_translation = translation_key.translations.find_by(locale: locale)
          if existing_translation.present? && existing_translation != proposed_translation
            existing_translation.update_attribute(:text, proposed_translation)
          else
            TranslationText.create(
                translation_key_id: translation_key.id,
                locale: locale,
                text: proposed_translation)
          end
        end
      end
    end

    def cohort_params
      params.require(:column_state).permit(
        visible: cohort_source.available_columns.map(&:column),
        editable: cohort_source.available_columns.map(&:column)
      )
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
