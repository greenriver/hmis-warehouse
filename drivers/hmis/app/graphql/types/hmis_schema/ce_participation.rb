###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeParticipation < Types::BaseObject
    include Types::HmisSchema::HasHudMetadata

    def self.configuration
      Hmis::Hud::CeParticipation.hmis_configuration(version: '2024')
    end

    hud_field :id, ID, null: false

    # nullable to be generous with imported data, even though its required.
    hud_field :access_point, HmisSchema::Enums::Hud::NoYes, null: true
    # nullable to be generous with imported data, even though its required.
    hud_field :ce_participation_status_start_date, null: true
    hud_field :ce_participation_status_end_date
    hud_field :ce_participation_services, [HmisSchema::Enums::CeParticipationServices], null: false
    hud_field :receives_referrals, HmisSchema::Enums::Hud::NoYes
  end
end
