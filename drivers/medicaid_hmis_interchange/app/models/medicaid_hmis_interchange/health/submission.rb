###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MedicaidHmisInterchange::Health
  class Submission < ::HealthBase
    has_one :response
    has_many :submission_external_ids
    has_many :external_ids, through: :submission_external_ids
  end
end
