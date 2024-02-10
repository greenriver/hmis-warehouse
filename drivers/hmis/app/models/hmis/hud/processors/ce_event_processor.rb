###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class CeEventProcessor < Base
    def relation_name
      :ce_event
    end

    def factory_name
      :ce_event_factory
    end

    def schema
      Types::HmisSchema::Event
    end

    def information_date(_)
    end
  end
end
