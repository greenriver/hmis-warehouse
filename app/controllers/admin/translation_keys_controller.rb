###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class TranslationKeysController < ApplicationController
    before_action :require_can_edit_translations!
    before_action :set_translation, only: [:show, :edit, :update, :destroy]
    before_action :add_default_locales_to_translation, only: [:show, :new]

    def index
      t_t = translation_source.arel_table
      search_options = params.require(:search).permit(:q, :missing_translations, :common) if params[:search]
      @search = Search.new(search_options)
      @translations = translation_source.order(key: :asc)
      if @search.q.present?
        @translations = @translations.where(
          t_t[:key].matches("%#{@search.q}%").
            or(
              t_t[:id].in(
                Arel.sql(
                  translation_source.where(t_t[:text].matches("%#{@search.q}%")).select(:id).to_sql,
                ),
              ),
            ),
        )
      end
      if @search.missing_translations
        @translations = @translations.
          where(
            id: translation_source.where(
              t_t[:text].eq(nil).or(t_t[:text].eq('')),
            ).select(:id),
          )
      end
      @translations = @translations.where(common: true) if @search.common

      @pagy, @translations = pagy(@translations)
      render action: :index
    end

    def new
      @translation = Translation.new

      render action: :edit
    end

    def show
      render action: :edit
    end

    def edit
      render action: :edit
    end

    def update
      if @translation.update(translation_params)
        @translation.invalidate_cache
        flash[:notice] = 'Saved!'
        redirect_to @translation
      else
        flash[:error] = 'Failed to save!'
        render action: :edit
      end
    end

    def translation_source
      Translation
    end

    def translation_params
      params.require(:translation).
        permit(
          :key,
          :text,
          :id,
        )
    end

    def set_translation
      @translation = Translation.find(params[:id].to_i)
    end

    class Search < ModelForm
      attribute :q, String, lazy: true, default: ''
      attribute :missing_translations, Boolean, lazy: true, default: false
      attribute :common, Boolean, lazy: true, default: false
    end
  end
end
