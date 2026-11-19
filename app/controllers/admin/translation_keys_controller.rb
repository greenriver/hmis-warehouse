###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class TranslationKeysController < ApplicationController
    before_action :require_can_edit_translations!

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

    def translation_source
      Translation
    end

    class Search < ModelForm
      attribute :q, String, lazy: true, default: ''
      attribute :missing_translations, Boolean, lazy: true, default: false
      attribute :common, Boolean, lazy: true, default: false
    end
  end
end
