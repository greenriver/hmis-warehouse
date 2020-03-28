###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class Triage < GrdaWarehouseBase
    include ::HealthEmergency

    def title
      'Screening'
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
