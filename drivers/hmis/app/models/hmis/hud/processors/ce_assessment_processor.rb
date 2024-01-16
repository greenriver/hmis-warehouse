###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class CeAssessmentProcessor < Base
    def factory_name
      case @processor.owner
      when Hmis::Hud::Assessment
        :owner_factory
      when Hmis::Hud::CustomAssessment
        :ce_assessment_factory
      else
        raise "processor owner #{@processor.owner_type} not hanlded"
      end
    end


    def schema
      Types::HmisSchema::CeAssessment
    end

    def information_date(_)
    end
  end
end
