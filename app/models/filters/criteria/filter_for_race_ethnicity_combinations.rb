# frozen_string_literal: true

class Filters::Criteria::FilterForRaceEthnicityCombinations < Filters::Criteria::Base
  def applies? = input.race_ethnicity_combinations.present?

  def apply(scope)
    scope = super(scope)
    race_ethnicity_scope = nil
    input.race_ethnicity_combinations.each do |combination|
      hispanic_latinaeo = combination.to_s.ends_with?('_hispanic_latinaeo')
      race_column = HudUtility2024.race_column_name(combination.to_s.gsub('_hispanic_latinaeo', ''))
      alternative = scope.race_ethnicity_alternative(race_column, hispanic_latinaeo)
      race_ethnicity_scope = add_alternative(race_ethnicity_scope, alternative)
    end

    scope.joins(config.join_clients_method).merge(race_ethnicity_scope)
  end
end
