###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SpmBasedReports
  extend ActiveSupport::Concern
  included do
    def spm_project_types
      HudUtility2024.spm_project_type_codes
    end

    def project_type_ids
      spm_project_types.map { |s| HudUtility2024.performance_reporting[s.to_sym] }.flatten
    end

    def project_options_for_select(user)
      GrdaWarehouse::Hud::Project.viewable_by(user).
        with_hud_project_type(project_type_ids).
        options_for_select(user: user)
    end
  end
end
