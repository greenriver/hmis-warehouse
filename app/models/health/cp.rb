###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
