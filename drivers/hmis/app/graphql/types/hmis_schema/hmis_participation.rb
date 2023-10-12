###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::HmisParticipation < Types::BaseObject
    include Types::HmisSchema::HasHudMetadata

    def self.configuration
      Hmis::Hud::HmisParticipation.hmis_configuration(version: '2024')
    end

    hud_field :id, ID, null: false
    # nullable to be generous with imported data, even though its required.
    hud_field :hmis_participation_type, HmisSchema::Enums::Hud::HMISParticipationType, null: true
    # nullable to be generous with imported data, even though its required.
    hud_field :hmis_participation_status_start_date, null: true
    hud_field :hmis_participation_status_end_date
  end
end
