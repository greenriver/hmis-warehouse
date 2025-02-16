class Filters::Criteria::FilterForRace < Filters::Criteria::Base
  def applies? = input.races.present?

  def apply(scope)
    race_scope = nil
    input.races.each do |column|
      next if column == 'MultiRacial'

      race_scope = add_alternative(race_scope, race_alternative(column.to_sym))
    end

    # Include anyone who has more than one race listed, anded with any previous alternatives
    race_scope ||= scope
    race_scope = race_scope.where(id: config.report_scope_source.multi_racial_clients.select(:id)) if input.races.include?('MultiRacial')
    scope.merge(race_scope)
  end

  protected

  def race_alternative(key)
    config.report_scope_source.joins(join_clients_method).where(arel.c_t[key].eq(1))
  end
end
