###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class HudFilterBase < FilterBase
    validates_presence_of :coc_codes

    # NOTE: This differs from the base filter class because it doesn't include any projects based on CoCCode
    def effective_project_ids
      @effective_project_ids = effective_project_ids_from_projects
      @effective_project_ids += effective_project_ids_from_project_groups
      @effective_project_ids += effective_project_ids_from_organizations
      @effective_project_ids += effective_project_ids_from_data_sources
      @effective_project_ids += effective_project_ids_from_project_types if project_type_codes_chosen

      # Add an invalid id if there are none
      @effective_project_ids = [0] if @effective_project_ids.empty?

      @effective_project_ids.uniq.reject(&:blank?)
    end
  end
end
