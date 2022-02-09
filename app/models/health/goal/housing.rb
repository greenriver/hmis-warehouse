###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented in base class
module Health
  class Goal::Housing < Goal::Base
    def self.type_name
      'Housing'
    end

    def to_partial_path
      "health/goal/clinicals/clinical"
    end
  end
end
