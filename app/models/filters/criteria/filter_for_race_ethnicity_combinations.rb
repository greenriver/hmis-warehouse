# frozen_string_literal: true

class Filters::Criteria::FilterForRaceEthnicityCombinations < Filters::Criteria::Base
  def applies? = input.race_ethnicity_combinations.present?

  def apply(scope)
    scope = super(scope).joins(config.join_clients_method)

    race_ethnicity_queries = input.race_ethnicity_combinations.map do |combination|
      hispanic_latinaeo = combination.to_s.ends_with?('_hispanic_latinaeo')
      race_column = HudUtility2024.race_column_name(combination.to_s.gsub('_hispanic_latinaeo', ''))
      scope.race_ethnicity_alternative(race_column, hispanic_latinaeo)
    end

    return scope if race_ethnicity_queries.empty?

    combined_query = race_ethnicity_queries.reduce(:or)
    scope.merge(combined_query)
  end
end
