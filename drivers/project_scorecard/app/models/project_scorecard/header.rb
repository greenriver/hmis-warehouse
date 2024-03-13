###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectScorecard
  module Header
    extend ActiveSupport::Concern
    included do
      def project_names
        project_name
      end

      def project_types
        HudUtility2024.project_type(key_project.project_type)
      end
    end
  end
end
