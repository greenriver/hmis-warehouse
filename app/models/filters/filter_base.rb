###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: This should be updated and added to for any functionality or additional attributes and only overridden where the defaults are different or where the options are incompatible with this base class.
module Filters
  class FilterBase < ::ModelForm
    include ArelHelper

    attribute :start, Date, lazy: true, default: -> (r,_) { r.default_start }
    attribute :end, Date, lazy: true, default: -> (r,_) { r.default_end }
    attribute :sort
    attribute :heads_of_household, Boolean, default: false
    attribute :comparison_pattern, Symbol, default: -> (r,_) { r.default_comparison_pattern }
    attribute :household_type, Symbol, default: :all
    attribute :hoh_only, Boolean, default: false
    attribute :project_type_codes, Array, default: -> (r,_) { r.default_project_type_codes }
    attribute :veteran_statuses, Array, default: []
    attribute :age_ranges, Array, default: []
    attribute :genders, Array, default: []
    attribute :races, Array, default: []
    attribute :ethnicities, Array, default: []
    attribute :length_of_times, Array, default: []
    attribute :destination_ids, Array, default: []
    attribute :prior_living_situation_ids, Array, default: []
    attribute :default_start, Date, default: (Date.current - 1.year).beginning_of_year
    attribute :default_end, Date, default: (Date.current - 1.year).end_of_year

    attribute :user_id, Integer, default: nil
    attribute :project_ids, Array, default: []
    attribute :project_group_ids, Array, default: []
    attribute :organization_ids, Array, default: []
    attribute :data_source_ids, Array, default: []
    attribute :funder_ids, Array, default: []
    attribute :cohort_ids, Array, default: []
    attribute :coc_codes, Array, default: []
    attribute :sub_population, Symbol, default: :clients
    attribute :start_age, Integer, default: 17
    attribute :end_age, Integer, default: 25
    attribute :ph, Boolean, default: false

    validates_presence_of :start, :end
    validate do
      if start > self.end
        errors.add(:end, 'End date must follow start date.')
      end
    end

    # NOTE: keep this up-to-date if adding additional attributes
    def cache_key
      [
        user.id,
        effective_project_ids,
        cohort_ids,
        coc_codes,
        sub_population,
        start_age,
        end_age,
      ]
    end

    def set_from_params(filters)
      return unless filters.present?

      self.start = filters.dig(:start)&.to_date
      self.end = filters.dig(:end)&.to_date
      self.comparison_pattern = clean_comparison_pattern(filters.dig(:comparison_pattern)&.to_sym)
      self.coc_codes = filters.dig(:coc_codes)&.select { |code| available_coc_codes.include?(code) }
      self.household_type = filters.dig(:household_type)&.to_sym
      self.heads_of_household = self.hoh_only = filters.dig(:hoh_only).in?(['1', 'true', true])
      self.project_type_codes = Array.wrap(filters.dig(:project_type_codes))&.reject { |type| type.blank? }.presence
      self.data_source_ids = filters.dig(:data_source_ids)&.reject(&:blank?)&.map(&:to_i)
      self.organization_ids = filters.dig(:organization_ids)&.reject(&:blank?)&.map(&:to_i)
      self.project_ids = filters.dig(:project_ids)&.reject(&:blank?)&.map(&:to_i)
      self.funder_ids = filters.dig(:funder_ids)&.reject(&:blank?)&.map(&:to_i)
      self.veteran_statuses = filters.dig(:veteran_statuses)&.reject(&:blank?)&.map(&:to_i)
      self.age_ranges = filters.dig(:age_ranges)&.reject(&:blank?)&.map { |range| range.to_sym }
      self.genders = filters.dig(:genders)&.reject(&:blank?)&.map { |gender| gender.to_i }
      self.sub_population = filters.dig(:sub_population)&.to_sym
      self.races = filters.dig(:races)&.select { |race| HUD.races.keys.include?(race) }
      self.ethnicities = filters.dig(:ethnicities)&.reject(&:blank?)&.map { |ethnicity| ethnicity.to_i }
      self.project_group_ids = filters.dig(:project_group_ids)&.reject(&:blank?)&.map { |group| group.to_i }
      self.prior_living_situation_ids = filters.dig(:prior_living_situation_ids)&.reject(&:blank?)&.map { |m| m.to_i }
      self.destination_ids = filters.dig(:destination_ids)&.reject(&:blank?)&.map { |m| m.to_i }
      self.length_of_times = filters.dig(:length_of_times)&.reject(&:blank?)&.map { |m| m.to_sym }
      ensure_dates_work
    end

    def for_params
      {
        filters: {
          start: start,
          end: self.end,
          comparison_pattern: comparison_pattern,
          coc_codes: coc_codes,
          household_type: household_type,
          project_type_codes: project_type_codes,
          data_source_ids: data_source_ids,
          organization_ids: organization_ids,
          project_ids: project_ids,
          funder_ids: funder_ids,
          veteran_statuses: veteran_statuses,
          age_ranges: age_ranges,
          genders: genders,
          sub_population: sub_population,
          races: races,
          ethnicities: ethnicities,
          project_group_ids: project_group_ids,
          hoh_only: hoh_only,
          prior_living_situation_ids: prior_living_situation_ids,
          destination_ids: destination_ids,
          length_of_times: length_of_times,
        }
      }
    end

    def range
      self.start .. self.end
    end

    def first
      range.begin
    end

    # fifteenth of relevant month
    def ides
      first + 14.days
    end

    def last
      range.end
    end

    def start_date
      first
    end

    def end_date
      last
    end

    def length
      (self.end - self.start).to_i rescue 0
    end

    def effective_project_ids
      @effective_project_ids = effective_project_ids_from_projects
      @effective_project_ids += effective_project_ids_from_project_groups
      @effective_project_ids += effective_project_ids_from_organizations
      @effective_project_ids += effective_project_ids_from_data_sources
      @effective_project_ids += effective_project_ids_from_coc_codes
      if @effective_project_ids.empty?
        @effective_project_ids = all_project_ids
      end
      return @effective_project_ids.uniq.reject(&:blank?)
    end

    def all_projects?
      effective_project_ids.sort == all_project_ids.sort
    end

    def project_ids
      @project_ids.reject(&:blank?)
    end

    def coc_codes
      @coc_codes.reject(&:blank?)
    end

    def project_group_ids
      @project_group_ids.reject(&:blank?)
    end

    def organization_ids
      @organization_ids.reject(&:blank?)
    end

    def data_source_ids
      @data_source_ids.reject(&:blank?)
    end

    def funder_ids
      @funder_ids.reject(&:blank?)
    end

    def cohort_ids
      @cohort_ids.reject(&:blank?)
    end

    def effective_project_ids_from_projects
      project_ids.reject(&:blank?).map(&:to_i)
    end

    def effective_project_ids_from_project_groups
      projects = project_group_ids.reject(&:blank?).map(&:to_i)
      return [] if projects.empty?

      GrdaWarehouse::ProjectGroup.joins(:projects).
        merge(GrdaWarehouse::ProjectGroup.viewable_by(user)).
          where(id: projects).
          pluck(p_t[:id].as('project_id'))
    end

    def effective_project_ids_from_organizations
      orgs = organization_ids.reject(&:blank?).map(&:to_i)
      return [] if orgs.empty?

      all_organizations_scope.
        where(id: orgs).
        pluck(p_t[:id].as('project_id'))
    end

    def effective_project_ids_from_data_sources
      sources = data_source_ids.reject(&:blank?).map(&:to_i)
      return [] if sources.empty?

      all_data_sources_scope.
        where(id: sources).
        pluck(p_t[:id].as('project_id'))
    end

    def effective_project_ids_from_coc_codes
      codes = coc_codes.reject(&:blank?)
      return [] if codes.empty?

      all_coc_code_scope.in_coc(coc_code: codes).
        pluck(p_t[:id].as('project_id'))
    end

    def all_project_ids
      all_project_scope.pluck(:id)
    end

    def all_project_scope
      GrdaWarehouse::Hud::Project.viewable_by(user)
    end

    def all_organizations_scope
      GrdaWarehouse::Hud::Organization.joins(:projects).
        merge(all_project_scope)
    end

    def all_data_sources_scope
      GrdaWarehouse::DataSource.joins(:projects).
        merge(all_project_scope)
    end

    def all_funders_scope
      GrdaWarehouse::Hud::Funder.joins(:project).
        merge(all_project_scope)
    end

    def all_coc_code_scope
      GrdaWarehouse::Hud::ProjectCoc.joins(:project).
        merge(all_project_scope)
    end

    def all_project_group_scope
      GrdaWarehouse::ProjectGroup.joins(:projects).
        merge(all_project_scope)
    end

    # Select display options
    def project_options_for_select(user: )
      all_project_scope.options_for_select(user: user)
    end

    def organization_options_for_select(user: )
      all_organizations_scope.options_for_select(user: user)
    end

    def data_source_options_for_select(user: )
      all_data_sources_scope.options_for_select(user: user)
    end

    def funder_options_for_select(user: )
      all_funders_scope.options_for_select(user: user)
    end

    def coc_code_options_for_select(user: )
      all_coc_code_scope.options_for_select(user: user)
    end

    def project_groups_options_for_select(user: )
      all_project_group_scope.options_for_select(user: user)
    end
    # End Select display options

    def clients_from_cohorts
      GrdaWarehouse::Hud::Client.joins(:cohort_clients).
        merge(GrdaWarehouse::CohortClient.active.where(cohort_id: cohort_ids)).
        distinct
    end

    def available_residential_project_types
      GrdaWarehouse::Hud::Project::RESIDENTIAL_TYPE_TITLES.invert
    end

    def available_homeless_project_types
      GrdaWarehouse::Hud::Project::HOMELESS_TYPE_TITLES.invert
    end

    def project_type_ids
      GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING.values_at(
        *project_type_codes.reject(&:blank?).map(&:to_sym)
      ).flatten
    end

    def selected_project_type_names
      GrdaWarehouse::Hud::Project::RESIDENTIAL_TYPE_TITLES.values_at(*project_type_codes.reject(&:blank?).map(&:to_sym))
    end

    def user
      User.find(user_id)
    end

    def available_age_ranges
      {
        under_eighteen: '< 18',
        eighteen_to_twenty_four: '18 - 24',
        twenty_five_to_sixty_one: '25 - 61',
        over_sixty_one: '62+',
      }.invert.freeze
    end

    def comparison_patterns
      {
        no_comparison_period: 'None',
        prior_year: 'Same period, prior year',
        prior_period: 'Prior Period',
      }.invert.freeze
    end

    def clean_comparison_pattern(pattern)
      comparison_patterns.values.detect { |m| m == pattern&.to_sym } || default_comparison_pattern
    end

    def available_coc_codes
      GrdaWarehouse::Hud::ProjectCoc.distinct.pluck(:CoCCode)
    end

    # disallow selection > 1 year, and reverse dates
    def ensure_dates_work
      ensure_date_order
      ensure_date_span
    end

    def ensure_date_order
      return unless last < first

      new_first = last
      self.end = first
      self.start = new_first
    end

    def ensure_date_span
      return if last - first < 365

      self.end = first + 1.years - 1.days
    end

    def default_comparison_pattern
      :no_comparison_period
    end

    def default_project_type_codes
      GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPE_CODES
    end

    def to_comparison
      comparison = deep_dup
      (comparison.start, comparison.end) = comparison_dates if comparison_pattern != :no_comparison_period
      comparison
    end

    private def comparison_dates
      case comparison_pattern
      when :prior_period
        prior_end = start_date - 1.days
        period_length = (end_date - start_date).to_i
        prior_start = prior_end - period_length.to_i.days
        [prior_start, prior_end]
      when :prior_year
        prior_end = end_date - 1.years
        prior_start = start_date - 1.years
        [prior_start, prior_end]
      else
        [start_date, end_date]
      end
    end
  end
end
