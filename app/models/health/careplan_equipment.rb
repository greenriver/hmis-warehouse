###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: None - contains no PHI
module Health
  class CareplanEquipment < HealthBase
    acts_as_paranoid

    belongs_to :careplans, class_name: 'Health::Careplan'
    belongs_to :equipments, class_name: 'Health::Equipment', optional: true
  end
end
