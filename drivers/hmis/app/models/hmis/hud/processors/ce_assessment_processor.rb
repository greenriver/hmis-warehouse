###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class CeAssessmentProcessor < Base
    def factory_name
      :ce_assessment_factory
    end

    def schema
      Types::HmisSchema::CeAssessment
    end

    def information_date(_)
    end
  end
end
