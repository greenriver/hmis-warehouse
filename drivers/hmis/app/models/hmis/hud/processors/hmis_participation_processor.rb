###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class HmisParticipationProcessor < Base
    def factory_name
      # Assumes that this record is only edited via its own form.
      # To support creating/editing from the Project form, we'd need to add a separate hmis_participation_factory
      :owner_factory
    end

    def schema
      Types::HmisSchema::HmisParticipation
    end

    def information_date(_)
    end
  end
end
