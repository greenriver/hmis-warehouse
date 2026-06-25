###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# ### HIPAA Risk Assessment
# Risk: None - contains no PHI
module Health
  class Base < HealthBase
    self.abstract_class = true

    def self.source_key= key
      @source_key = key
    end
    def self.source_key
      @source_key
    end

    def self.known_sub_classes
      [
        Health::Appointment,
        Health::Careplan,
        Health::Medication,
        Health::Patient,
        Health::Problem,
        Health::Team,
        Health::Visit,
        Health::EpicGoal,
      ]
    end

  end
end
