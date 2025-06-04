# frozen_string_literal: true

# Filters::Criteria provides a modular system for building and applying filter conditions to HMIS reporting queries.
# It uses a factory pattern to instantiate criteria objects based on filter definitions, and provides utilities
# for working with groups of related criteria.
#
# Each criteria class represents a specific type of filter (e.g., age range, project type, etc.) and follows
# a consistent interface with `applies?` and `apply` methods.
#
# @example Creating and applying a single criterion
#   filter = Filters::FilterBase.new(user_id: current_user.id, age_ranges: [:under_eighteen])
#   criterion = Filters::Criteria.factory(:filter_for_age, input: filter)
#   filtered_scope = criterion.apply(scope) if criterion.applies?
#
# @example Finding criteria classes that match certain tags
#   client_criteria = Filters::Criteria.classes_for_tags([:warehouse, :client])
#
module Filters::Criteria
  # Returns an array of criteria classes that match all specified tags
  #
  # @param tags [Array<Symbol>] List of tags that must all be present on the criteria
  # @return [Array<Class>] Array of criteria classes that match all specified tags
  def self.classes_for_tags(tags)
    definitions = DEFINITIONS.values.filter do |dfn|
      tags.all? { |tag| dfn[:tags].include?(tag) }
    end
    definitions.map { |dfn| dfn[:class_name].constantize }
  end

  # Creates a new criteria instance for the specified criterion ID
  #
  # @param criterion_id [Symbol] The ID of the criterion to instantiate
  # @param input [Filters::FilterBase] The filter input containing parameters
  # @param config [Filters::Criteria::Configuration, nil] Optional configuration
  # @return [Filters::Criteria::Base] A new criteria instance
  # @raise [KeyError] If criterion_id is not found in DEFINITIONS
  def self.factory(criterion_id, input:, config: nil)
    dfn = DEFINITIONS.fetch(criterion_id)
    dfn[:class_name].constantize.new(input: input, config: config)
  end

  # Gets the criterion ID for a given criteria class
  #
  # @param criteria_class [Class] The criteria class
  # @return [Symbol] The criterion ID
  # @raise [KeyError] If class is not found in CLASS_ID_LOOKUP
  def self.class_id(criteria_class)
    CLASS_ID_LOOKUP.fetch(criteria_class.sti_name)
  end

  # Returns all available criterion IDs
  #
  # @return [Array<Symbol>] Array of all criterion IDs
  def self.criterion_ids
    DEFINITIONS.keys
  end

  # Criteria definitions mapping criterion IDs to their metadata
  # Each definition includes:
  # - tags: Array of symbols categorizing the criterion (e.g., :hud, :warehouse, :client)
  # - id: Symbol identifying the criterion
  # - class_name: String name of the criterion class
  #
  # @api private
  DEFINITIONS = {
    filter_for_user_access: { tags: [:hud, :warehouse, :project] },
    filter_for_projects_hud: { tags: [:hud] },
    filter_for_project_cocs: { tags: [:hud] },
    filter_for_veteran_status: { tags: [:hud, :warehouse, :client] },
    filter_for_household_type: { tags: [:hud, :warehouse, :client] },
    filter_for_head_of_household: { tags: [:hud, :warehouse, :client] },
    filter_for_age: { tags: [:hud, :warehouse, :client] },
    filter_for_gender: { tags: [:hud, :warehouse, :client] },
    filter_for_race: { tags: [:hud, :warehouse, :client] },
    filter_for_sub_population: { tags: [:hud, :warehouse, :client] },
    filter_for_enrollment_cocs: { tags: [:hud] },
    filter_for_range: { tags: [:warehouse, :project] },
    filter_for_cocs: { tags: [:warehouse, :project] },
    filter_for_project_type: { tags: [:warehouse, :project] },
    filter_for_projects: { tags: [:warehouse, :project] },
    filter_for_funders: { tags: [:warehouse, :project] },
    filter_for_data_sources: { tags: [:warehouse, :project] },
    filter_for_organizations: { tags: [:warehouse, :project] },
    filter_for_prior_living_situation: { tags: [:warehouse, :client] },
    filter_for_destination: { tags: [:warehouse, :client] },
    filter_for_disabilities: { tags: [:warehouse, :client] },
    filter_for_indefinite_disabilities: { tags: [:warehouse, :client] },
    filter_for_dv_status: { tags: [:warehouse, :client] },
    filter_for_dv_currently_fleeing: { tags: [:warehouse, :client] },
    filter_for_chronic_at_entry: { tags: [:warehouse, :client] },
    filter_for_chronic_status: { tags: [:warehouse, :client] },
    filter_for_rrh_move_in: { tags: [:warehouse, :client] },
    filter_for_psh_move_in: { tags: [:warehouse, :client] },
    filter_for_first_time_homeless_in_past_two_years: { tags: [:warehouse, :client] },
    filter_for_returned_to_homelessness_from_permanent_destination: { tags: [:warehouse, :client] },
    filter_for_ce_homeless: { tags: [:warehouse, :client] },
    filter_for_ce_cls_homeless: { tags: [:warehouse, :client] },
    filter_for_cohorts: { tags: [:warehouse, :client] },
    filter_for_active_roi: { tags: [:warehouse, :client] },
    filter_for_times_homeless: { tags: [:warehouse, :client] },
    filter_for_days_since_contact: { tags: [:warehouse, :client] },
    filter_for_race_ethnicity_combinations: { tags: [] },
  }.each_with_object({}) { |(key, dfn), result| result[key] = dfn.merge({ id: key, class_name: "Filters::Criteria::#{key.to_s.camelize}" }) }.freeze

  # Lookup table mapping class names to criterion IDs
  IDS_BY_CLASS = DEFINITIONS.values.to_h { |dfn| dfn.values_at(:class_name, :id) }.freeze
end
