###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: None - contains no PHI
module Health
  class Cp < HealthBase
    # You should only ever have one sender
    scope :sender, -> { where sender: true }

    def self.find_by_pidsl(pidsl)
      find_by(
        pid: pidsl[0...-1], # Drop the SL off the PID/SL to get the PID
        sl: pidsl.last,
      )
    end

  end
end
