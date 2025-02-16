module Filters::Criteria
  def self.classes_for_tags(tags)
    definitions = DEFINITIONS.values.filter do |df|
      tags.all? { |tag| df[:tags].include?(tag) }
    end
    definitions.map { |df| df[:class_name].constantize }
  end

  def self.factory(criterion_id, input:, config: nil)
    DEFINITIONS.fetch(criterion_id).new(input: input, config: config)
  end

  def self.class_id(criteria_class)
    CLASS_ID_LOOKUP.fetch(criteria_class.sti_name)
  end

  def self.criterion_ids
    DEFINITIONS.keys
  end

  DEFINITIONS = [
    { tags: [:hud, :warehouse, :project], id: :filter_for_user_access },
    { tags: [:hud], id: :filter_for_projects_hud },
    { tags: [:hud], id: :filter_for_project_cocs },
    { tags: [:hud], id: :filter_for_veteran_status },
    { tags: [:hud, :warehouse, :client], id: :filter_for_household_type },
    { tags: [:hud, :warehouse, :client], id: :filter_for_head_of_household },
    { tags: [:hud, :warehouse, :client], id: :filter_for_age },
    { tags: [:hud, :warehouse, :client], id: :filter_for_gender },
    { tags: [:hud, :warehouse, :client], id: :filter_for_race },
    { tags: [:hud], id: :filter_for_sub_population },
    { tags: [:hud], id: :filter_for_enrollment_cocs },

    { tags: [:warehouse, :project], id: :filter_for_range },
    { tags: [:warehouse, :project], id: :filter_for_cocs },
    { tags: [:warehouse, :project], id: :filter_for_project_type },
    { tags: [:warehouse, :project], id: :filter_for_projects },
    { tags: [:warehouse, :project], id: :filter_for_funders },
    { tags: [:warehouse, :project], id: :filter_for_data_sources },
    { tags: [:warehouse, :project], id: :filter_for_organizations },

    { tags: [:warehouse, :client], id: :filter_for_veteran_status },
    { tags: [:warehouse, :client], id: :filter_for_sub_population },
    { tags: [:warehouse, :client], id: :filter_for_prior_living_situation },
    { tags: [:warehouse, :client], id: :filter_for_destination },
    { tags: [:warehouse, :client], id: :filter_for_disabilities },
    { tags: [:warehouse, :client], id: :filter_for_indefinite_disabilities },
    { tags: [:warehouse, :client], id: :filter_for_dv_status },
    { tags: [:warehouse, :client], id: :filter_for_dv_currently_fleeing },
    { tags: [:warehouse, :client], id: :filter_for_chronic_at_entry },
    { tags: [:warehouse, :client], id: :filter_for_chronic_status },
    { tags: [:warehouse, :client], id: :filter_for_rrh_move_in },
    { tags: [:warehouse, :client], id: :filter_for_psh_move_in },
    { tags: [:warehouse, :client], id: :filter_for_first_time_homeless_in_past_two_years },
    { tags: [:warehouse, :client], id: :filter_for_returned_to_homelessness_from_permanent_destination },
    { tags: [:warehouse, :client], id: :filter_for_ca_homeless },
    { tags: [:warehouse, :client], id: :filter_for_ce_cls_homeless },
    { tags: [:warehouse, :client], id: :filter_for_cohorts },
    { tags: [:warehouse, :client], id: :filter_for_active_roi },
    { tags: [:warehouse, :client], id: :filter_for_times_homeless },
    { tags: [:warehouse, :client], id: :filter_for_days_since_contact },
    { tags: [], id: :filter_for_race_ethnicity_combinations },
  ].map { |df| df.merge({ class_name: "Filters::Criteria::#{df[:id].to_s.camelize}" }) }.
    index_by { |h| h[:id] }.
    freeze

  IDS_BY_CLASS = DEFINITIONS.values.to_h { |df| df.values_at(:class_name, :id) }.freeze
end
