module Admin
  class TranslationKeysController < ApplicationController
    before_action :require_can_edit_translations!
    before_action :find_translation_key, only: [:show, :edit, :update, :destroy]
    before_action :add_default_locales_to_translation, only: [:show, :new]

    def index
      tt_t = TranslationText.arel_table
      tk_t = translation_key_source.arel_table

      search_options = params.require(:search).permit(:q, :missing_translations) if params[:search]
      @search = Search.new(search_options)
      @translation_keys = translation_key_source.order(key: :asc)  
      if @search.q.present?
        @translation_keys = @translation_keys.where(tk_t[:key].matches("%#{@search.q}%"))
      end
      if @search.missing_translations
        @translation_keys = @translation_keys.
          where(
            id: translation_text_source.where(
              tt_t[:text].eq(nil).or(tt_t[:text].eq('')
            )).select(:translation_key_id)
          )
      end
      
      @translation_keys = @translation_keys.page(params[:page]).per(25)
      render action: :index
    end

    def new
      @translation_key = TranslationKey.new
      
      render action: :edit
    end

    def show
      render action: :edit
    end

    def edit
      render action: :edit
    end

    def update
      if @translation_key.update(translation_key_params)
        flash[:notice] = 'Saved!'
        redirect_to @translation_key
      else
        flash[:error] = 'Failed to save!'
        render action: :edit
      end
    end
    
    def translation_key_source
      TranslationKey
    end
    def translation_text_source
      TranslationText
    end  
    
    def translation_key_params
      params.require(:translation_key).
        permit(
          :key, 
          translations_attributes: [:id, :text, :locale]
        )
    end
    
    def self.tbe_config
      @@tbe_config ||= YAML::load(File.read(Rails.root.join('config','translation_db_engine.yml'))).with_indifferent_access rescue {}
    end

    def choose_layout
      self.class.tbe_config[:layout] || 'application'
    end

    def find_translation_key
      @translation_key = TranslationKey.find(params[:id].to_i)
    end

    def add_default_locales_to_translation
      existing_translations = @translation_key.translations.map(&:locale)
      missing_translations = TranslationKey.available_locales.map(&:to_sym) - existing_translations.map(&:to_sym)
      missing_translations.each do |locale|
        @translation_key.translations.build(:locale => locale)
      end
    end
    
    class Search < ModelForm
      attribute :q, String, lazy: true, default: ''
      attribute :missing_translations, Boolean, lazy: true, default: false
      
    end
  end
end
