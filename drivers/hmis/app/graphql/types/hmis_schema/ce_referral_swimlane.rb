###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeReferralSwimlane < Types::BaseObject
    # object is an OpenStruct amalgamation of:
    # - Hmis::WorkflowDefinition::Swimlane, the swimlane definition
    # - [Hmis::Ce::ReferralParticipant], the participants for this swimlane on this referral
    #
    # See CeReferral.swimlanes for how this object is constructed.

    field :id, ID, null: false,
                   description: 'Same as swimlaneId (unchanged for backwards compatibility). Can be updated to resolve cacheKey value once frontend is updated to send swimlaneId to assignReferralParticipants.'
    field :cache_key, ID, null: false,
                          description: 'Referral-scoped key for Apollo cache to avoid collisions across referrals.'
    field :swimlane_id, ID, null: false,
                            description: 'Template swimlane id; same as id. Use as assignReferralParticipants.swimlaneId.'
    field :name, String, null: false, description: 'Swimlane name'
    field :participants, [Application::User], null: false, description: 'Assigned users for this swimlane on this referral'
  end
end
