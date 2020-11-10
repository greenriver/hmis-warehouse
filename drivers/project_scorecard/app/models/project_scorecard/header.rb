###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectScorecard
  module Header
    extend ActiveSupport::Concern
    included do
      def project_names
        project.name
      end

      def project_types
        HUD.project_type(project.compute_project_type)
      end
    end
  end
end
