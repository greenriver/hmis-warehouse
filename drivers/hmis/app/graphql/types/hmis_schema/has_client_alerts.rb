#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Types
  module HmisSchema
    module HasClientAlerts
      extend ActiveSupport::Concern

      def resolve_client_alerts(scope = object.alerts)
        scope
      end
    end
  end
end
