###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Hud::Processors
  class WorkflowStepProcessor < Base
    def factory_name
      :owner_factory
    end

    def schema
      Types::HmisSchema::CeReferralStep
    end

    def assign_metadata
      # nothing to assign
    end

    def information_date(_)
    end
  end
end
