###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented in base class
module Health
  class Goal::Hpc < Goal::Base
    def self.type_name
      'Goal'
    end

    def self.available_stati
      [
        'Identified',
        'In-progress',
        'Completed',
      ]
    end
  end
end
