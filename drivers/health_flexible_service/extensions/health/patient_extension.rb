###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthFlexibleService::Health
  module PatientExtension
    extend ActiveSupport::Concern

    included do
      has_many :flexible_services, class_name: 'HealthFlexibleService::Vpr'
      has_many :flexible_service_follow_ups, class_name: 'HealthFlexibleService::VprFollowUp'
    end
  end
end
