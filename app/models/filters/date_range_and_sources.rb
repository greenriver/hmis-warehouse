###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
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
          merge(GrdaWarehouse::Hud::Project.viewable_by(user)).
          where(id: organization_ids.reject(&:blank?).map(&:to_i)).
          pluck(p_t[:id].as('project_id').to_sql)
    end

    def effective_project_ids_from_data_sources
      GrdaWarehouse::DataSource.joins(:projects).
          merge(GrdaWarehouse::Hud::Project.viewable_by(user)).
          where(id: data_source_ids.reject(&:blank?).map(&:to_i)).
          pluck(p_t[:id].as('project_id').to_sql)
    end

    def all_project_ids
      GrdaWarehouse::Hud::Project.viewable_by(user).pluck(:id)
    end

    def user
      User.find(user_id)
    end
  end
end