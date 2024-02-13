###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class EmploymentEducationProcessor < Base
    def factory_name
      :employment_education_factory
    end

    def schema
      Types::HmisSchema::EmploymentEducation
    end

    def relation_name
      :employment_education
    end
  end
end
