###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
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

  end
end