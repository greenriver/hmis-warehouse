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
                   description: 'Swimlane id; client should pass this as assignReferralParticipants.swimlaneId'
    field :cache_key, ID, null: false,
                          description: 'Referral-scoped key for Apollo cache to avoid collisions across referrals'
    field :name, String, null: false, description: 'Swimlane name'
    field :participants, [Application::User], null: false, description: 'Assigned users for this swimlane on this referral'
  end
end
