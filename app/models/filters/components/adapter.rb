module Filters::Components
  # Extracted from filter scopes
  class Adapter
    attr_reader :user, :input
    def initialize(user:, input:)
      @user = user
      @input = input
    end

    def filter_for_projects(scope)
      filter = combine_filters.new(
        filters: [
          filter_factory(:project_id, project_ids: input.project_ids),
          filter_factory(:project_group_id, project_group_ids: input.project_group_ids),
        ]
      )
      filter.apply(scope)
    end

    private def filter_for_projects_hud(scope)
      return scope.none if @filter.project_ids.blank?
      filter_factory(:project_id, project_ids: input.project_ids)
    end

    private def filter_for_age(scope)
      return scope unless input.age_ranges.present?

      filter_factory(:age_range, age_ranges: input.age_ranges)
    end

    protected

    FILTER_FACTORIES = {
      project_id: 'Filters::Components::ProjectIdFilter',
      project_group_id: 'Filters::Components::ProjectGroupIdFilter',
      age_range: 'Filters::Components::AgeRangeFilter',
    }.freeze

    def factory(name, **args)
      FILTER_FACTORIES.fetch(name).constantize.new(**args)
    end

    def combine_filters
      filtered_scope = filters.map { |filter| filter.apply(scope) }.reduce { |a, b| a.or(b) }
      scope.where(id: filtered_scope.select(:id))
    end

  end
end
