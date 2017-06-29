class TranslationKeysController < ApplicationController
  before_action :require_can_edit_translations!
  before_action :find_translation_key, only: [:show, :edit, :update, :destroy]
  before_action :add_default_locales_to_translation, only: [:show, :new]

  def index
    @search = params.require(:search).permit(:q) if params[:search]
    @query = @search[:q] if @search.present?
    keys = if @query.blank?
      TranslationKey
    else
      tk_t = TranslationKey.arel_table
      TranslationKey.where(tk_t[:key].matches("%#{@query}%"))
      
    end.order(key: :asc)

    if params[:missing_lang]
      unless params[:missing_lang] == ""
        keys = keys.joins(:translations).
          where(
            tk_t[:text].is(nil).
            or(tk_t[:text].eq(''))
            .and(tk_t[:locale].eq(params.require(:language).permit(:missing_lang)))
          )
      end
    end
    @translation_keys = keys#.page(2).per(25)

    render action: :index
  end

  def new
    @skip_authorization = true
    @translation_key = TranslationKey.new
    
    render action: :edit
  end

  def authorized?
    true
  end

  def show
    @skip_authorization = true
    
    render action: :edit
  end

  def edit
    @skip_authorization = true
    render action: :edit
  end

  def update
    console
    if @translation_key.update(translation_key_params)
      flash[:notice] = 'Saved!'
      redirect_to @translation_key
    else
      flash[:error] = 'Failed to save!'
      render action: :edit
    end
  end
  
  protected  
  
  def translation_key_params
    # To Permit a Hash, Pass an Array
    # http://patshaughnessy.net/2014/6/16/a-rule-of-thumb-for-strong-parameters
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
end
