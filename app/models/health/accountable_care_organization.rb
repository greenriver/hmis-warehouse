###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: None - contains no PHI
module Health
  class AccountableCareOrganization < HealthBase
    before_save :clean_up
    validates_presence_of :name

    has_many :patient_referrals

    scope :active, -> { where active: true }
    scope :inactive, -> { where active: false }

    def self.split_pid_sl(pid_sl)
      return { pid: nil, sl: nil } unless pid_sl.present?

      {
        pid: pid_sl[0, pid_sl.length - 1],
        sl:  pid_sl[-1],
      }
    end

    def clean_up
      name.squish!
      short_name.squish!
      edi_name.squish!
    end
  end
end
