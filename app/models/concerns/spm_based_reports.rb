###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SpmBasedReports
  extend ActiveSupport::Concern
  included do
    def spm_project_types
      GrdaWarehouse::Hud::Project::SPM_PROJECT_TYPE_CODES
    end

    def project_type_ids
      spm_project_types.map { |s| GrdaWarehouse::Hud::Project::PERFORMANCE_REPORTING[s.to_sym] }.flatten
    end

    def project_options_for_select(user)
      GrdaWarehouse::Hud::Project.viewable_by(user).
        with_hud_project_type(project_type_ids).
        options_for_select(user: user)
    end
  end
end
