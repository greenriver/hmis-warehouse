###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MedicaidHmisInterchange::Health
  class Response < ::HealthBase
    belongs_to :submission
    has_many :response_external_ids
    has_many :external_ids, through: :response_external_ids
  end
end
