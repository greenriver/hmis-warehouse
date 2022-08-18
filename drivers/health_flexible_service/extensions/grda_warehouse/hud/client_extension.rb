###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthFlexibleService::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern

    included do
      has_many :health_flexible_services, class_name: 'HealthFlexibleService::Vpr'
      has_many :health_flexible_service_follow_ups, class_name: 'HealthFlexibleService::VprFollowUp'
      belongs_to :health_housing_navigator, class_name: 'User', optional: true

      def available_health_housing_navigators
        # If the client has a patient and is assigned to an agency, limit the pick list to users at that agency
        # Otherwise, list include all active health users assigned to an agency
        agency_id = patient&.health_agency&.id
        if agency_id
          user_ids = Health::AgencyUser.where(agency_id: agency_id, user_id: User.active.pluck(:id)).pluck(:user_id)
        else
          user_ids = Health::AgencyUser.where(user_id: User.active.pluck(:id)).pluck(:user_id)
        end

        user_ids << health_housing_navigator_id if health_housing_navigator_id.present?
        User.where(id: user_ids)
      end
    end
  end
end
