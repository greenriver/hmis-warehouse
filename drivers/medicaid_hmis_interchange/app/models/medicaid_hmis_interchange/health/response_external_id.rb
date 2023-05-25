###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MedicaidHmisInterchange::Health
  class ResponseExternalId < ::HealthBase
    belongs_to :response
    belongs_to :external_id
  end
end
