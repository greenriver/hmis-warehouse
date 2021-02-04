###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: None - contains no PHI
module Health
  class Base < HealthBase
    self.abstract_class = true

    class << self
      attr_writer :source_key
    end

    class << self
      attr_reader :source_key
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
