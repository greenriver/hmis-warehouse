###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Search
  extend ActiveSupport::Concern

  included do
    private def search_setup(columns: [], search: nil, scope: nil, search_object: nil)
      columns = Array.wrap(columns)
      search ||= search_scope
      return search unless search_object || search_params[:q].present?

      @search_string = search_object&.query_params.try(:[], :q) || search_params[:q]&.strip
      # Pass the query to the selected scope if present
      return search.send(scope, @search_string) unless scope.nil?

      return search if columns.blank?

      # Otherwise search the columns provided for a match
      query = search.klass.arel_table[columns.first].matches("%#{@search_string}%")
      columns.drop(1).each do |column|
        query = query.or(search.klass.arel_table[column].matches("%#{@search_string}%"))
      end
      search.where(query)
    end

    private def search_params
      return {} unless params[:search_form]

      params.require(:search_form).permit(:q)
    end
  end
end
