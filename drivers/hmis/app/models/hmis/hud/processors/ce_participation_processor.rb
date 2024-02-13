###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Processors
  class CeParticipationProcessor < Base
    def factory_name
      # Assumes that this record is only edited via its own form.
      # To support creating/editing from the Project form, we'd need to add a separate ce_participation_factory
      :owner_factory
    end

    def relation_name
      :ce_participation
    end

    def schema
      Types::HmisSchema::CeParticipation
    end

    def information_date(_)
    end
  end
end
