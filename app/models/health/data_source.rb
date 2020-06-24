###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: None - contains no PHI
module Health
  class DataSource < Base
    acts_as_paranoid

    has_many :patients
    has_many :medications
    has_many :problems
    has_many :appointments
    has_many :visits
    has_many :epic_goals

  end
end
