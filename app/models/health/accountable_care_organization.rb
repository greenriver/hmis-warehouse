###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: None - contains no PHI
module Health
  class AccountableCareOrganization < HealthBase

    validates_presence_of :name

    has_many :patient_referrals

    scope :active, -> { where active: true }

    def self.split_pid_sl(pid_sl)
      return { pid: nil, sl: nil } unless pid_sl.present?

      {
        pid: pid_sl[0, pid_sl.length - 1],
        sl:  pid_sl[-1],
      }
    end
  end
end