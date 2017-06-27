# class TranslationKeysController < ApplicationController
#   before_filter :authenticate
#   before_filter :find_translation_key, :only=>%w[show edit update destroy]
# 
#   def index
#     @translation_keys = TranslationKey.find(:all)
#   end
# 
#   def new
#     @translation_key = TranslationKey.new
#     add_default_locales_to_translation
#     render :action=>:edit
#   end
# 
#   def create
#     @translation_key = TranslationKey.new(params[:translation_key])
#     if @translation_key.save
#       flash[:notice] = 'Created!'
#       redirect_to translation_key_path(@translation_key)
#     else
#       flash[:error] = 'Failed to save!'
#       render :action=>:edit
#     end
#   end
# 
#   def show
#     add_default_locales_to_translation
#     render :action=>:edit
#   end
# 
#   def edit
#   end
# 
#   def update
#     if @translation_key.update_attributes(params[:translation_key])
#       flash[:notice] = 'Saved!'
#       redirect_to @translation_key
#     else
#       flash[:error] = 'Failed to save!'
#       render :action=>:edit
#     end
#   end
# 
#   def destroy
#     @translation_key.destroy
#     redirect_to translation_keys_path
#   end
# 
#   protected
# 
#   def self.tbe_config
#     @@tbe_config ||= YAML::load(File.read(Rails.root.join('config','translation_db_engine.yml'))).with_indifferent_access rescue {}
#   end
# 
#   def choose_layout
#     self.class.tbe_config[:layout] || 'application'
#   end
# 
#   def authenticate
#     return unless auth = self.class.tbe_config[:auth]
#     authenticate_or_request_with_http_basic do |username, password|
#       username == auth[:name] && password == auth[:password]
#     end
#   end
# 
#   def find_translation_key
#     @translation_key = TranslationKey.find(params[:id])
#   end
# 
#   def add_default_locales_to_translation
#     existing_translations = @translation_key.translations.map(&:locale)
#     missing_translations = TranslationKey.available_locales.map(&:to_sym) - existing_translations.map(&:to_sym)
#     missing_translations.each do |locale|
#       @translation_key.translations.build(:locale => locale)
#     end
#   end
# end
