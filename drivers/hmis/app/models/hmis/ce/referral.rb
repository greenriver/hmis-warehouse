# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# A referral of an individual client to an opportunity
module Hmis::Ce
  class Referral < GrdaWarehouseBase
    include SimpleStateMachine

    belongs_to :opportunity, class_name: 'Hmis::Ce::Opportunity'
    belongs_to :workflow_instance, class_name: 'Hmis::WorkflowExecution::Instance'
    has_many :notes, class_name: 'Hmis::Ce::ReferralNote'
    has_many :participants, class_name: 'Hmis::Ce::ReferralParticipant'
    belongs_to :client, class_name: 'Hmis::Hud::Client'
    belongs_to :referred_by, class_name: 'Hmis::User'
    # Referral belongs_to household, not enrollment, because we don't want to lose the association if the originally
    # referred member leaves the household but other household members are still occupying the unit.
    belongs_to :target_enrollment, class_name: 'Hmis::Hud::Enrollment', optional: true

    # TODO(#7395): permissions
    scope :viewable_by, ->(_user) { all }

    scope :active, -> { where.not(status: ['accepted', 'rejected']) }

    state_machine_config column: 'status' do
      state :initialized, initial: true
      state :in_progress
      state :accepted
      state :rejected

      event :start do
        transitions from: :initialized, to: :in_progress
      end
      event :accept do
        transitions from: :in_progress, to: :accepted
      end
      event :reject do
        transitions from: :in_progress, to: :rejected
      end
      # event :stall do
      #   transitions from: :active, to: :stalled
      # end
    end

    def workflow_engine
      @workflow_engine ||= Hmis::WorkflowExecution::Engine.new(
        workflow_instance,
        message_handler: Hmis::Ce::ReferralMessageHandler.new(self),
        assignment_handler: Hmis::Ce::ReferralTaskAssignmentHandler.new(self),
      )
    end
  end
end
