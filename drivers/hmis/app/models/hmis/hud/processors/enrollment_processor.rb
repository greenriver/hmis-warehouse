###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class EnrollmentProcessor < Base
    def factory_name
      :enrollment_factory
    end

    def schema
      Types::HmisSchema::Enrollment
    end

    def information_date(_)
      # Enrollments don't have an information date to be set
    end
  end
end
