###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class Triage < GrdaWarehouseBase
    include ::HealthEmergency

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
      return "Referred on #{referred_on}" if referred_to && referred_on
      return 'Referred' if referred_to
      return 'Cleared' if exposure == 'No' && symptoms == 'No'

      'Unknown'
    end
  end
end
