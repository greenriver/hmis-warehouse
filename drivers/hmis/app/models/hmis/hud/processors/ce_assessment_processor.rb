###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class CeAssessmentProcessor < Base
    def factory_name
      :ce_assessment_factory
    end

    def relation_name
      :ce_assessment
    end

    def schema
      Types::HmisSchema::CeAssessment
    end

    def information_date(_)
    end

    # This record type can be conditionally collected on CustomAssessments
    def dependent_destroyable?
      true
    end
  end
end
