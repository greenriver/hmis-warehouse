###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class Triage < GrdaWarehouseBase
    belongs_to :user
    belongs_to :agency

    def exposure_options
      [ 'Yes', 'No' ]
    end

    def symptom_options
      [ 'Yes', 'No' ]
    end
  end
end
