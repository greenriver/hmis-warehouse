###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
    hud_field :crisis_assessment, HmisSchema::Enums::Hud::NoYes
    hud_field :direct_services, HmisSchema::Enums::Hud::NoYes
    hud_field :housing_assessment, HmisSchema::Enums::Hud::NoYes
    hud_field :prevention_assessment, HmisSchema::Enums::Hud::NoYes
    hud_field :receives_referrals, HmisSchema::Enums::Hud::NoYes
  end
end
