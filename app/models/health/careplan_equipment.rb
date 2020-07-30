###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: None - contains no PHI
module Health
  class CareplanEquipment < HealthBase

    acts_as_paranoid

    belongs_to :careplans, class_name: 'Health::Careplan'
    belongs_to :equipments, class_name: 'Health::Equipment'

  end
end