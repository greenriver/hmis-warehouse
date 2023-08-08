###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthThriveAssessment::Health
  module PatientExtension
    extend ActiveSupport::Concern

    included do
      has_many :thrive_assessments, class_name: 'HealthThriveAssessment::Assessment'
    end
  end
end
