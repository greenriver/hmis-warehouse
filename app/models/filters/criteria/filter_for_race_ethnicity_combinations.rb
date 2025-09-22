# frozen_string_literal: true

class Filters::Criteria::FilterForRaceEthnicityCombinations < Filters::Criteria::Base
  def applies? = input.race_ethnicity_combinations.present?

  def apply(scope)
    scope = super(scope).joins(config.join_clients_method)

    return scope if input.race_ethnicity_combinations.empty?

    # Convert combinations to race selections with individual Hispanic status
    race_selections = input.race_ethnicity_combinations.map do |combination|
      hispanic_latinaeo = combination.to_s.ends_with?('_hispanic_latinaeo')
      race_column = HudUtility2026.race_column_name(combination.to_s.gsub('_hispanic_latinaeo', ''))

      { race: race_column.to_sym, hispanic: hispanic_latinaeo }
    end

    builder = RaceEthnicityQueryBuilder.new(race_selections)
    builder.apply_to_scope(scope, arel.c_t)
  end
end
