# frozen_string_literal: true

# A role/user who is participating in the referral process.
# What is the difference between a ReferralParticipant and a StepAssignment?
# - A ReferralParticipant represents the general, not-step-specific concept of a "contact" on this referral. It says,
#   "Whenever a task that's for Swimlane X becomes available on this referral, assign it to User A and User B".
#   ReferralParticipants can be created by users from the frontend, or they can be created at referral creation time
#   based on some defaults for the referral context.
# - A StepAssignment represents the more specific concept of the user who is assigned to this particular task.
#   StepAssignments are created by the workflow engine when a task becomes available, based on the ReferralParticipants
#   for this step's Swimlane. A StepAssignment is also created when a user starts a task, even if they aren't a
#   participant in this swimlane.
module Hmis::Ce
  class ReferralParticipant < GrdaWarehouseBase
    belongs_to :referral, class_name: 'Hmis::Ce::Referral'
    belongs_to :user, class_name: 'Hmis::User'
    belongs_to :swimlane, class_name: 'Hmis::WorkflowDefinition::Swimlane'

    validates :user_id, uniqueness: { scope: [:referral_id, :swimlane_id], message: 'must be unique per referral and swimlane' }
  end
end
