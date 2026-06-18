###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Hud::Processors
  class HealthAndDvProcessor < Base
    def factory_name
      :health_and_dv_factory
    end

    def relation_name
      :health_and_dv
    end

    def schema
      Types::HmisSchema::HealthAndDv
    end
  end
end
