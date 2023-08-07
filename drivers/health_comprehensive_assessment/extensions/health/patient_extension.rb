###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthComprehensiveAssessment::Health
  module PatientExtension
    extend ActiveSupport::Concern

    included do
      has_many :comprehensive_assessments, class_name: 'HealthComprehensiveAssessment::Assessment'
    end
  end
end
