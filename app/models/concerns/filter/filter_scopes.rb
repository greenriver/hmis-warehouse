###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filter::FilterScopes
  extend ActiveSupport::Concern
  included do
    # we extracted these methods into discrete classes but keep methods to preserve backwards compatibility
    [
      # hud
      :filter_for_user_access,
      :filter_for_projects_hud,
      :filter_for_project_cocs,
      :filter_for_veteran_status,
      :filter_for_household_type,
      :filter_for_head_of_household,
      :filter_for_age,
      :filter_for_gender,
      :filter_for_race,
      :filter_for_sub_population,
      :filter_for_enrollment_cocs,

      # projects
      :filter_for_user_access,
      :filter_for_range,
      :filter_for_cocs,
      :filter_for_project_type,
      :filter_for_projects,
      :filter_for_funders,
      :filter_for_data_sources,
      :filter_for_organizations,

      # client
      :filter_for_household_type,
      :filter_for_head_of_household,
      :filter_for_age,
      :filter_for_gender,
      :filter_for_race,
      :filter_for_veteran_status,
      :filter_for_sub_population,
      :filter_for_prior_living_situation,
      :filter_for_destination,
      :filter_for_disabilities,
      :filter_for_indefinite_disabilities,
      :filter_for_dv_status,
      :filter_for_dv_currently_fleeing,
      :filter_for_chronic_at_entry,
      :filter_for_chronic_status,
      :filter_for_rrh_move_in,
      :filter_for_psh_move_in,
      :filter_for_first_time_homeless_in_past_two_years,
      :filter_for_returned_to_homelessness_from_permanent_destination,
      :filter_for_ca_homeless,
      :filter_for_ce_cls_homeless,
      :filter_for_cohorts,
      :filter_for_active_roi,
      :filter_for_times_homeless,
      :filter_for_days_since_contact,
      :filter_for_days_since_contact,

      # other
      :filter_for_race_ethnicity_combinations,
    ].each do |method|
      define_method(method) do |scope|
        criterion_class = "Filters::Criteria::#{method.to_s.camelize}".constantize
        criterion = criterion_class.new(input: filter, config: criteria_configuration)
        criterion.applies? ? criterion.apply(scope) : scope
      end
    end

    def criteria_configuration
      # special case handling to allow for @project_types ivar which is seems to override filter.project_type_ids
      @criteria_configuration ||= Filters::Criteria::Configuration.new(project_types: @project_types)
    end

    # FIXME factor this out
    private def age_calculation
      age_on_date(@filter.start_date)
    end
  end
end
