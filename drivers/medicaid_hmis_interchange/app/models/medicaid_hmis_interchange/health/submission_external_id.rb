###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MedicaidHmisInterchange::Health
  class SubmissionExternalId < ::HealthBase
    belongs_to :submission
    belongs_to :external_id
  end
end
