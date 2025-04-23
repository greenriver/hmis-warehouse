###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeReferralSwimlane < Types::BaseObject
    # An amalgamation of:
    # - Hmis::WorkflowDefinition::Swimlane, the swimlane definition
    # - Hmis::Ce::ReferralParticipant, the participants for this swimlane on this referral

    field :id, ID, null: false
    field :name, String, null: false
    field :assigned_users, [Application::User], null: false
  end
end
