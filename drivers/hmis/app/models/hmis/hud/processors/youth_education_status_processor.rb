###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Hud::Processors
  class YouthEducationStatusProcessor < Base
    def factory_name
      :youth_education_status_factory
    end

    def relation_name
      :youth_education_status
    end

    def schema
      Types::HmisSchema::YouthEducationStatus
    end
  end
end
