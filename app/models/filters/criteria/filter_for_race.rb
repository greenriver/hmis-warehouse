# frozen_string_literal: true

class Filters::Criteria::FilterForRace < Filters::Criteria::Base
  def applies? = input.races.present?

  def apply(scope)
    scope = super(scope)
    race_scope = nil
    input.races.each do |column|
      next if column == 'MultiRacial'

      race_scope = add_alternative(race_scope, race_alternative(column.to_sym))
    end

    race_scope ||= scope
    return race_scope unless input.races.include?('MultiRacial')

    # Include anyone who has more than one race listed, anded with any previous alternatives
    mr_scope = config.report_scope_source.multi_racial_clients.joins(config.join_clients_method).select(:id)
    scope.merge(race_scope.where(id: mr_scope.select(:id)))
  end

  protected

  def race_alternative(key)
    config.report_scope_source.joins(config.join_clients_method).where(arel.c_t[key].eq(1))
  end
end
