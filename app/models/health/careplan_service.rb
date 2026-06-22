###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# ### HIPAA Risk Assessment
# Risk: None - contains no PHI
module Health
  class CareplanService < HealthBase

    acts_as_paranoid

    belongs_to :careplans, class_name: 'Health::Careplan', optional: true
    belongs_to :services, class_name: 'Health::Service', optional: true

  end
end
