###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class ReferralRequestProcessor < Base
    def factory_name
      :owner_factory
    end

    def schema
      Types::HmisSchema::ReferralRequest
    end

    def information_date(_)
    end

    def assign_metadata
      record = @processor.send(factory_name)
      return if record.persisted?

      record.assign_attributes(requested_by: @processor.current_user)
    end
  end
end
