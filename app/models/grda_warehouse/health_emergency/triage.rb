###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class Triage < GrdaWarehouseBase
    include ::HealthEmergency

    def visible_to?(user)
      user.can_see_health_emergency_screening?
    end

    def title
      'Screening'
    end

    def sort_date
      referred_on || updated_at
    end

    def exposure_options
      {
        'Unknown' => '',
        'Yes' => 'Yes',
        'No' => 'No',
      }
    end

    def symptom_options
      {
        'Unknown' => '',
        'Yes' => 'Yes',
        'No' => 'No',
      }
    end

    def status
      return "Referred #{referred_on}" if referred_to.present? && referred_on
      return 'Referred' if referred_to.present?
      return 'Cleared' if exposure == 'No' && symptoms == 'No'
      return 'Screened' if exposure || symptoms

      'Unknown'
    end
  end
end
