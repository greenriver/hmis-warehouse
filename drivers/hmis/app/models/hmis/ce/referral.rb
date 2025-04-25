###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
    belongs_to :target_enrollment, class_name: 'Hmis::Hud::Enrollment', optional: true
    has_one :target_project, class_name: 'Hmis::Hud::Project', through: :opportunity, source: :project
    has_many :steps, class_name: 'Hmis::WorkflowExecution::Step', through: :workflow_instance

    # There can be multiple open steps, but we want to show one "current step this referral is on" in the UI
    has_one :current_step, -> { open.order_by_status.limit(1) }, class_name: 'Hmis::WorkflowExecution::Step', through: :workflow_instance, source: :steps

    # TODO(#7395): permissions
    scope :viewable_by, ->(_user) { all }

    scope :active, -> { where.not(status: ['accepted', 'rejected']) }
    scope :active_or_accepted, -> { where.not(status: 'rejected') }

    validate :unique_referral_per_opportunity

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

    def active?
      !accepted? && !rejected?
    end

    private

    def unique_referral_per_opportunity
      # Opportunities are single-use, so there should only be one in-progress or accepted referral,
      # but there could be many rejected referrals.
      return if status.to_sym == :rejected

      conflicting_referral_exists = Hmis::Ce::Referral.where.not(status: 'rejected').
        where(opportunity_id: opportunity_id).
        where.not(id: id).
        exists?
      return unless conflicting_referral_exists

      errors.add(:opportunity, 'can only have one active or accepted referral')
    end
  end
end
