###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class ScheduledDocuments::EnrollmentDisenrollment < Health::ScheduledDocuments::Base
    validates :acos, presence: true

    def params
      [
        acos: [],
      ]
    end
  end
end
