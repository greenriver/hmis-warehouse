class Filters::Criteria::FilterForRace < Filters::Criteria::Base
  LEVEL = :client

  def applies? = input.races.present?

  def apply(scope)
    race_scope = nil
    input.races.each do |column|
      next if column == 'MultiRacial'

      race_scope = add_alternative(race_scope, race_alternative(column.to_sym))
    end

    # Include anyone who has more than one race listed, anded with any previous alternatives
    race_scope ||= scope
    race_scope = race_scope.where(id: multi_racial_clients.select(:id)) if input.races.include?('MultiRacial')
    scope.merge(race_scope)
  end

  protected

  def race_alternative(key)
    report_scope_source.joins(join_clients_method).where(c_t[key].eq(1))
  end

  def multi_racial_clients(include_hispanic_latinaeo: false)
    # Looking at all races with responses of 1, where we have a sum > 1
    columns = [
      arel.c_t[:AmIndAKNative],
      arel.c_t[:Asian],
      arel.c_t[:BlackAfAmerican],
      arel.c_t[:NativeHIPacific],
      arel.c_t[:White],
      arel.c_t[:MidEastNAfrican],
    ]
    columns << arel.c_t[:HispanicLatinaeo] if include_hispanic_latinaeo

    report_scope_source.joins(config.join_clients_method).
      where(Arel.sql(columns.map(&:to_sql).join(' + ')).between(2..98))
  end
end
