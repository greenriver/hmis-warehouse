###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filter::FilterScopes
  extend ActiveSupport::Concern
  included do
    def criteria_configuration
      # special case handling to allow for @project_types ivar which is seems to override filter.project_type_ids
      @criteria_configuration ||= Filters::Criteria::Configuration.new(
        project_types: @project_types,
      )
    end

    private def filter_for_race_ethnicity_combinations(scope)
      return scope unless @filter.race_ethnicity_combinations.present?

      race_ethnicity_scope = nil
      @filter.race_ethnicity_combinations.each do |combination|
        hispanic_latinaeo = combination.to_s.ends_with?('_hispanic_latinaeo')
        race_column = HudUtility2024.race_column_name(combination.to_s.gsub('_hispanic_latinaeo', ''))
        alternative = race_ethnicity_alternative(scope, race_column, hispanic_latinaeo)
        race_ethnicity_scope = add_alternative(race_ethnicity_scope, alternative)
      end

      scope.joins(join_clients_method).merge(race_ethnicity_scope)
    end

    def race_ethnicity_alternative(scope, key, hispanic_latinaeo = false)
      columns = (HudUtility2024.race_fields - [:RaceNone]).map { |k| [k, 0] }.to_h

      key = key.to_sym
      if key.in?([:MultiRacial, :multi_racial])
        query = multi_racial_clients(include_hispanic_latinaeo: false)
        query = query.where(c_t[:HispanicLatinaeo].eq(hispanic_latinaeo ? 1 : 0))
        return scope.merge(query)
      elsif key.in?([:RaceNone, :race_none])
        return scope.where(c_t[:RaceNone].in([8, 9, 99]))
      else
        columns[key] = 1
        columns[:HispanicLatinaeo] = 1 if hispanic_latinaeo
        query = nil
        columns.each do |k, v|
          if query.nil?
            query = c_t[k].eq(v)
          else
            query = query.and(c_t[k].eq(v))
          end
        end
        scope.where(query)
      end
    end

    private def filter_for_projects_hud(scope)
      return scope.none if @filter.project_ids.blank?

      scope.in_project(@filter.project_ids).merge(GrdaWarehouse::Hud::Project.viewable_by(@filter.user, permission: :can_view_assigned_reports))
    end

    # we extracted these methods into discrete classes but keep methods to preserve
    # backwards compatibility
    Filters::Criteria::CriteriaSet::CRITERIA_CLASS_NAMES.each do |class_name|
      method = class_name.demodulize.underscore
      define_method(method) do |scope|
        criterion = class_name.constantize.for_input(input: self, config: criteria_configuration)
        criterion ? criterion.apply(scope) : scope
      end
    end
  end
end
