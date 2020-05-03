###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Filters
  class DateRangeAndSources < DateRange
    include ArelHelper

    attribute :user_id, Integer, default: nil
    attribute :project_ids, Array, default: []
    attribute :project_group_ids, Array, default: []
    attribute :organization_ids, Array, default: []
    attribute :data_source_ids, Array, default: []
    attribute :cohort_ids, Array, default: []
    attribute :sub_population, Symbol, default: :all_clients
    attribute :start_age, Integer, default: 17
    attribute :end_age, Integer, default: 25
    attribute :all_project_scope, Scope, lazy: true, default: -> () { GrdaWarehouse::Hud::Project.viewable_by(user) }

    validates_presence_of :start, :end

    def effective_project_ids
      @effective_project_ids = effective_project_ids_from_projects
      @effective_project_ids += effective_project_ids_from_project_groups
      @effective_project_ids += effective_project_ids_from_organizations
      @effective_project_ids += effective_project_ids_from_data_sources
      if @effective_project_ids.empty?
        @effective_project_ids = all_project_ids
      end
      return @effective_project_ids.uniq
    end

    def all_projects?
      effective_project_ids.sort == all_project_ids.sort
    end

    def effective_project_ids_from_projects
      project_ids.reject(&:blank?).map(&:to_i)
    end

    def effective_project_ids_from_project_groups
      GrdaWarehouse::ProjectGroup.joins(:projects).
        merge(GrdaWarehouse::ProjectGroup.viewable_by(user)).
          where(id: project_group_ids.reject(&:blank?).map(&:to_i)).
          pluck(p_t[:id].as('project_id').to_sql)
    end

    def effective_project_ids_from_organizations
      GrdaWarehouse::Hud::Organization.joins(:projects).
          merge(all_project_scope).
          where(id: organization_ids.reject(&:blank?).map(&:to_i)).
          pluck(p_t[:id].as('project_id').to_sql)
    end

    def effective_project_ids_from_data_sources
      GrdaWarehouse::DataSource.joins(:projects).
          merge(all_project_scope).
          where(id: data_source_ids.reject(&:blank?).map(&:to_i)).
          pluck(p_t[:id].as('project_id').to_sql)
    end

    def all_project_ids
      all_project_scope.pluck(:id)
    end

    def clients_from_cohorts
      GrdaWarehouse::Hud::Client.joins(:cohort_clients).
        merge(GrdaWarehouse::CohortClient.active.where(cohort_id: cohort_ids)).
        distinct
    end

    def user
      User.find(user_id)
    end
  end
end