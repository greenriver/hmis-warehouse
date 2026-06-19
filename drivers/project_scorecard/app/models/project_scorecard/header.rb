###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ProjectScorecard
  module Header
    extend ActiveSupport::Concern
    included do
      def project_names
        project_name
      end

      def project_types
        HudHelper.util.project_type(key_project.project_type)
      end
    end
  end
end
