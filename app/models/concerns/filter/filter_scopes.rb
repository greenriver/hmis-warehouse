###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filter::FilterScopes
  extend ActiveSupport::Concern
  included do
    # we extracted these methods into discrete classes but keep methods to preserve backwards compatibility
    Filters::Criteria.criterion_ids.each do |criterion_id|
      define_method(criterion_id) do |scope|
        run_applicable_criteria(criterion_id, scope)
      end
    end

    # run the criteria on scope if applicable using the current filter as the input
    def run_applicable_criteria(criterion_id, scope)
      criterion = Filters::Criteria.factory(criterion_id, input: filter, config: criteria_configuration)
      criterion.applies? ? criterion.apply(scope) : scope
    end

    def criteria_configuration(**opts)
      # special case handling to allow for @project_types instance var which is seems to override filter.project_type_ids
      defaults = { project_types: @project_types }
      Filters::Criteria::Configuration.new(**defaults.merge(opts))
    end

    # FIXME factor this out
    private def age_calculation
      age_on_date(@filter.start_date)
    end
  end
end
