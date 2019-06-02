###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: None - contains no PHI
module Health
  class CareplanService < HealthBase

    acts_as_paranoid

    belongs_to :careplans, class_name: Health::Careplan.name
    belongs_to :services, class_name: Health::Service.name

  end
end