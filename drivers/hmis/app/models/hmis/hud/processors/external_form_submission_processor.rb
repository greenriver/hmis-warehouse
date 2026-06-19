###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

    def information_date(_)
    end
  end
end
