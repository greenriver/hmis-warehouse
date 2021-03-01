###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Filters
  class AprFilter < ::Filters::FilterBase
    validates_presence_of :coc_codes
    validate do
      errors.add(:project_ids, 'or project groups must be specified') if project_ids.blank? && project_group_ids.blank?
    end

    # NOTE: This differs from the base filter class because it includes all projects based on project type, and doesn't include any projects based on CoCCode
    def effective_project_ids
      @effective_project_ids = effective_project_ids_from_projects
      @effective_project_ids += effective_project_ids_from_project_groups
      @effective_project_ids += effective_project_ids_from_organizations
      @effective_project_ids += effective_project_ids_from_data_sources
      @effective_project_ids += effective_project_ids_from_project_types
      @effective_project_ids = all_project_ids if @effective_project_ids.empty?

      @effective_project_ids.uniq.reject(&:blank?)
    end
  end
end
