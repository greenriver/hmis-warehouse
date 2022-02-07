###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class ClinicalTriage < GrdaWarehouseBase
    include ::HealthEmergency

    def visible_to?(user)
      user.can_see_health_emergency_clinical?
    end

    def title
      'Clinical Screening'
    end

    def sort_date
      updated_at
    end

    def show_pill_in_history?
      false
    end

    def requested_options
      {
        'Unknown' => '',
        'Yes' => 'Yes',
        'No' => 'No',
      }
    end

    def status
      test_requested
    end
  end
end
