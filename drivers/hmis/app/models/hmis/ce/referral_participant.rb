# frozen_string_literal: true

# A role/user who is participating in the referral process
module Hmis::Ce
  class ReferralParticipant < GrdaWarehouseBase
    belongs_to :referral, class_name: 'Hmis::Ce::Referral'
    belongs_to :user, class_name: 'Hmis::User'
    belongs_to :swimlane, class_name: 'Hmis::WorkflowDefinition::Swimlane'

    validates :user_id, uniqueness: { scope: [:referral_id, :swimlane_id], message: 'must be unique per referral and swimlane' }
  end
end
