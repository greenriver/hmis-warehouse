###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BostonProjectScorecard
  module Header
    extend ActiveSupport::Concern
    included do
      def project_sponsor
        return project.organization_name if project.present?

        project_group.projects.map(&:organization_name).uniq.join(', ')
      end

      def project_type_options
        project_group.projects.map do |project|
          [project.human_readable_project_type, project.project_type]
        end.uniq
      end

      def secondary_reviewer_options
        all_data_sources = AccessGroup.find_by(name: 'All Data Sources')
        all_data_sources.users.active.not_system
      end
    end
  end
end
