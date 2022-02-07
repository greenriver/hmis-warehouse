###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
        HUD.project_type(key_project.computed_project_type)
      end
    end
  end
end
