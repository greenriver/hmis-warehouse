###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::GrdaWarehouse::Hud
  module EnrollmentExtension
    extend ActiveSupport::Concern

    included do
      has_many :custom_services, **Hmis::Hud::Base.hmis_enrollment_relation('CustomService'), inverse_of: :enrollment
      has_many :hmis_custom_assessments, **Hmis::Hud::Base.hmis_enrollment_relation('CustomAssessment'), inverse_of: :enrollment
    end
  end
end
