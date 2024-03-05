###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class CustomAssessmentProcessor < Base
    def factory_name
      :owner_factory
    end

    def relation_name
      :custom_assessment
    end

    def schema
      Types::HmisSchema::Assessment
    end

    def information_date(_)
    end
  end
end
