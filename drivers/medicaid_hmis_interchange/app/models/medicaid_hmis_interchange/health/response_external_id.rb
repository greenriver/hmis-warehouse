###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module MedicaidHmisInterchange::Health
  class ResponseExternalId < ::HealthBase
    belongs_to :response
    belongs_to :external_id
  end
end
