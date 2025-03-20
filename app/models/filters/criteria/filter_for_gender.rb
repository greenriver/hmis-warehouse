# frozen_string_literal: true

class Filters::Criteria::FilterForGender < Filters::Criteria::Base
  def applies? = input.genders.present?

  def apply(scope)
    scope = super(scope)
    scope = scope.joins(config.join_clients_method)

    gender_queries = input.genders.filter_map do |value|
      column = HudUtility2024.gender_id_to_field_name[value]
      next unless column

      config.report_scope_source.
        joins(config.join_clients_method).
        where(arel.c_t[column.to_sym].eq(HudUtility2024.gender_comparison_value(value)))
    end

    return scope if gender_queries.empty?

    combined_query = gender_queries.reduce(:or)
    scope.merge(combined_query)
  end
end
