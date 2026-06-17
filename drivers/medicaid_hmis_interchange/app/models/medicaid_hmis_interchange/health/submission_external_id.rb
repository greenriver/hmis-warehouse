###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module MedicaidHmisInterchange::Health
  class SubmissionExternalId < ::HealthBase
    belongs_to :submission
    belongs_to :external_id
  end
end
