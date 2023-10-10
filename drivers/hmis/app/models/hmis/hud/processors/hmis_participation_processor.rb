###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class HmisParticipationProcessor < Base
    def factory_name
      :owner_factory # fixme - allow set on new project form?
    end

    def schema
      Types::HmisSchema::HmisParticipation
    end

    def information_date(_)
    end
  end
end
