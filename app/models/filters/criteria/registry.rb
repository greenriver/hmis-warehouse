class Filters::Criteria::Registry

  def self.hud
    HUD_CRITERIA_IDS.map { |id| get(id) }
  end

  def self.warehouse_projects
    WH_PROJECT_CRITERIA_IDS.map { |id| get(id) }
  end

  def self.warehouse_projects
    WH_CLIENT_CRITERIA_IDS.map { |id| get(id) }
  end

  def self.get(id)
    "Filters::Criteria::#{id.to_s.camelize}".constantize
  end

  HUD_CRITERIA_IDS = [
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
  ].freeze

  WH_PROJECT_CRITERIA_IDS = [
    :filter_for_user_access,
    :filter_for_range,
    :filter_for_cocs,
    :filter_for_project_type,
    :filter_for_projects,
    :filter_for_funders,
    :filter_for_data_sources,
    :filter_for_organizations,
  ].freeze

  WH_CLIENT_CRITERIA_IDS = [
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
  ].freeze

  ALL_IDS = (HUD_CRITERIA_IDS + WH_PROJECT_CRITERIA_IDS + WH_CLIENT_CRITERIA_IDS).uniq
end
