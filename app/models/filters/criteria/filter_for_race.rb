# frozen_string_literal: true

class Filters::Criteria::FilterForRace < Filters::Criteria::Base
  def applies? = input.races.present?

  def apply(scope)
    scope = super(scope)

    # Remove empty strings from races array
    races = input.races.compact_blank

    # If all race options are selected, we should include all clients
    return scope if all_races_selected?(races)

    race_queries = races.filter_map do |column|
      case column
      when 'RaceNone'
        race_none_alternative
      when 'MultiRacial'
        nil # Handled separately below
      else
        race_alternative(column)
      end
    end

    scope = scope.merge(race_queries.reduce(:or)) if race_queries.any?

    # Handle MultiRacial separately if it's included
    if races.include?('MultiRacial')
      # Include anyone who has more than one race listed
      mr_scope = scope.multi_racial_clients.joins(config.join_clients_method)
      scope = scope.where(id: mr_scope.select(:id))
    end

    scope
  end

  protected

  def race_columns
    @race_columns ||= HudUtility2024.race_fields.map(&:to_s)
  end

  def race_alternative(key)
    config.report_scope_source.joins(config.join_clients_method).where(arel.c_t[key].eq(1))
  end

  def race_none_alternative
    data_quality_values = [1, 8, 9, 99]
    columns = race_columns.grep_v('RaceNone')

    config.report_scope_source.joins(config.join_clients_method).where(
      arel.c_t[:RaceNone].in(data_quality_values).or(
        columns.map { |field| arel.c_t[field].eq(nil) }.reduce(:and),
      ),
    )
  end

  def all_races_selected?(races)
    (race_columns - races).empty?
  end
end
