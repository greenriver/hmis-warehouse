# frozen_string_literal: true

class Filters::Criteria::FilterForRace < Filters::Criteria::Base
  def applies? = input.races.present?

  def apply(scope)
    scope = super(scope)

    race_queries = input.races.filter_map do |column|
      race_alternative(column.to_sym) if column != 'MultiRacial'
    end

    scope = scope.merge(race_queries.reduce(:or)) if race_queries.any?

    return scope unless input.races.include?('MultiRacial')

    # Include anyone who has more than one race listed, anded with any previous alternatives
    mr_scope = scope.multi_racial_clients.joins(config.join_clients_method)
    scope.where(id: mr_scope.select(:id))
  end

  protected

  def race_alternative(key)
    config.report_scope_source.joins(config.join_clients_method).where(arel.c_t[key].eq(1))
  end
end
