###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class DateRangeAndSources < DateRange
    include ArelHelper

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
    attribute :project_type_codes, Array, default: []
    attribute :gender, Integer, default: nil
    attribute :race, String, default: nil
    attribute :ethnicity, Integer, default: nil

    validates_presence_of :start, :end

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
        ph,
        project_type_codes,
        gender,
        race,
        ethnicity,
      ]
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

    def effective_project_ids
      @effective_project_ids = effective_project_ids_from_projects
      @effective_project_ids += effective_project_ids_from_project_groups
      @effective_project_ids += effective_project_ids_from_organizations
      @effective_project_ids += effective_project_ids_from_data_sources
      @effective_project_ids += effective_project_ids_from_coc_codes
      @effective_project_ids = all_project_ids if @effective_project_ids.empty?
      return @effective_project_ids.uniq.reject(&:blank?)
    end

    def all_projects?
      effective_project_ids.sort == all_project_ids.sort
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

    def project_options_for_select(user:)
      all_project_scope.distinct.options_for_select(user: user)
    end

    def organization_options_for_select(user:)
      all_organizations_scope.distinct.options_for_select(user: user)
    end

    def data_source_options_for_select(user:)
      all_data_sources_scope.distinct.options_for_select(user: user)
    end

    def funder_options_for_select(user:)
      all_funders_scope.distinct.options_for_select(user: user)
    end

    def coc_code_options_for_select(user:)
      all_coc_code_scope.distinct.options_for_select(user: user)
    end

    def project_groups_options_for_select(user:)
      all_project_group_scope.distinct.options_for_select(user: user)
    end

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
        *project_type_codes.reject(&:blank?).map(&:to_sym),
      ).flatten
    end

    def selected_project_type_names
      GrdaWarehouse::Hud::Project::RESIDENTIAL_TYPE_TITLES.values_at(*project_type_codes.reject(&:blank?).map(&:to_sym))
    end

    def user
      User.find(user_id)
    end
  end
end
