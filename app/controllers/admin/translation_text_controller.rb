module Admin  
  class TranslationTextController < ApplicationController
    before_action :require_can_edit_translations!
    before_action :find_translation_text

    def update
      error = false
      begin
        tp = text_params
        @text.update(text_params)
        if tp[:text].blank?
          @text.text = nil
          @text.save
        end
      rescue Exception => e
        error = true
        render status: 500, json: 'Unable to save translation', layout: false
      end
      text = text_params[:text]
      render status: 200, json: "Translation saved: #{text}", layout: false unless error
    end

    def translation_text_source
      TranslationText
    end  
    
    def find_translation_text
      @text = translation_text_source.find(params[:id].to_i)
    end  
    
    def text_params
      params.require(:translation_text).permit(:text, :id, :locale)
    end
  end
end
