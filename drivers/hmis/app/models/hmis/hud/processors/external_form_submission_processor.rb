###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class ExternalFormSubmissionProcessor < Base
    def factory_name
      :owner_factory
    end

    def schema
      Types::HmisSchema::ExternalFormSubmission
    end

    def assign_metadata
      # nothing to assign
    end
  end
end
