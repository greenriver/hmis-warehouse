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
        return project.name if project.present?

        project_group.projects.map(&:name).join(', ')
      end

      def project_types
        return HUD.project_type(project.compute_project_type) if project.present?

        project_group.projects.map(&:compute_project_type).join(', ')
      end
    end
  end
end
