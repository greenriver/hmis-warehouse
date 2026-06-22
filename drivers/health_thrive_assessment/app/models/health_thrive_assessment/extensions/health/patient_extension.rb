###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HealthThriveAssessment::Health
  module PatientExtension
    extend ActiveSupport::Concern

    included do
      has_many :thrive_assessments, class_name: 'HealthThriveAssessment::Assessment'
    end
  end
end
