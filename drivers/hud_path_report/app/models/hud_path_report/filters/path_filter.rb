###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Filters
  class PathFilter < ::Filters::FilterBase
    def default_project_type_codes
      [:so, :services_only]
    end

    # NOTE: This differs from the base filter class because it includes all projects based on project type, and doesn't include any projects based on CoCCode
    def effective_project_ids
      ids = effective_project_ids_from_projects
      ids += effective_project_ids_from_project_groups
      ids += effective_project_ids_from_organizations
      ids += effective_project_ids_from_data_sources
      ids = all_project_ids if ids.empty?

      ids = ids.uniq.reject(&:blank?)
      ids &= effective_project_ids_from_project_types if effective_project_ids_from_project_types.present?
      ids
    end
  end
end
