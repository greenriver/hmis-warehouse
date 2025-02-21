class Filters::Criteria::FilterForRaceEthnicityCombinations < Filters::Criteria::Base
  def applies? = input.race_ethnicity_combinations.present?

  def apply(scope)
    race_ethnicity_scope = nil
    input.race_ethnicity_combinations.each do |combination|
      hispanic_latinaeo = combination.to_s.ends_with?('_hispanic_latinaeo')
      race_column = HudUtility2024.race_column_name(combination.to_s.gsub('_hispanic_latinaeo', ''))
      alternative = race_ethnicity_alternative(scope, race_column, hispanic_latinaeo)
      race_ethnicity_scope = add_alternative(race_ethnicity_scope, alternative)
    end

    scope.joins(config.join_clients_method).merge(race_ethnicity_scope)
  end

  def race_ethnicity_alternative(scope, key, hispanic_latinaeo = false)
    columns = (HudUtility2024.race_fields - [:RaceNone]).map { |k| [k, 0] }.to_h

    key = key.to_sym
    if key.in?([:MultiRacial, :multi_racial])
      query = multi_racial_clients(include_hispanic_latinaeo: false)
      query = query.where(arel.c_t[:HispanicLatinaeo].eq(hispanic_latinaeo ? 1 : 0))
      return scope.merge(query)
    elsif key.in?([:RaceNone, :race_none])
      return scope.where(arel.c_t[:RaceNone].in([8, 9, 99]))
    else
      columns[key] = 1
      columns[:HispanicLatinaeo] = 1 if hispanic_latinaeo
      query = nil
      columns.each do |k, v|
        if query.nil?
          query = arel.c_t[k].eq(v)
        else
          query = query.and(arel.c_t[k].eq(v))
        end
      end
      scope.where(query)
    end
  end
end
