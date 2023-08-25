###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthComprehensiveAssessment
  class SudTreatment < HealthBase
    belongs_to :assessment

    def inpatient?
      inpatient == 'inpatient'
    end

    def completed?
      completed == 'yes'
    end
  end
end
