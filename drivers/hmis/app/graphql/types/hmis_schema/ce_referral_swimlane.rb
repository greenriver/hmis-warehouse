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

    field :id, ID, null: false
    field :name, String, null: false
    field :participants, [Application::User], null: false
  end
end
