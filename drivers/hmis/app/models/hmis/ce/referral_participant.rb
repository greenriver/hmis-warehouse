# A role/user who is participating in the referral process
module Hmis::Ce
  class ReferralParticipant < GrdaWarehouseBase
    belongs_to :referral, class_name: 'Hmis::Ce::Referral'
    belongs_to :user, class_name: 'Hmis::User'
    belongs_to :swimlane, class_name: 'Hmis::WorkflowDefinition::Swimlane'
  end
end
