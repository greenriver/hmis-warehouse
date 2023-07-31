###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class CurrentLivingSituationProcessor < Base
    def factory_name
      :current_living_situation_factory
    end

    def schema
      Types::HmisSchema::CurrentLivingSituation
    end
  end
end
