###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ProjectCoordinatedEntryFeatures < Types::BaseObject
    # Object is an OpenStruct representing the coordinated entry features that are enabled for this project
    field :id, ID, null: false

    field :accepts_direct_referrals, Boolean, null: false, description: 'Whether this project accepts direct CE referrals, initiated by a sending project'
    field :supports_waitlist_referrals, Boolean, null: false, description: 'Whether this project supports waitlist CE referrals, initiated internally from a unit waitlist'
    field :sends_direct_referrals, Boolean, null: false, description: 'Whether this project sends direct CE Referrals'
    field :supports_referrals, Boolean, null: false, description: 'Whether this project supports referrals, either direct or waitlist'
  end
end
