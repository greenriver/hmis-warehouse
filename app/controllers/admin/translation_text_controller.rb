###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class TranslationTextController < ApplicationController
    before_action :require_can_edit_translations!
    before_action :set_translation

    def update
      error = false
      begin
        @translation.assign_attributes(text_params)
        @translation.text = nil if text_params[:text]&.strip&.blank?
        @translation.save
        @translation.invalidate_cache
      rescue Exception
        error = true
        render status: 500, json: 'Unable to save translation', layout: false
      end
      text = text_params[:text]
      render status: 200, json: "Translation saved: #{text}", layout: false unless error
    end

    def translation_source
      Translation
    end

    def set_translation
      @translation = translation_source.find(params[:id].to_i)
    end

    def text_params
      params.require(:translation).permit(:text, :id)
    end
  end
end
