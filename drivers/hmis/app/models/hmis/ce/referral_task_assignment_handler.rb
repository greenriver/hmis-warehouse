# frozen_string_literal: true

# Given a workflow task, determine users to be assigned
module Hmis::Ce
  class ReferralTaskAssignmentHandler
    attr_reader :referral
    def initialize(referral)
      @referral = referral
    end

    # Determine which users to assign to a task.
    # Currently uses swimlanes. Perhaps we should add a fallback or other strategies
    def call(task)
      return [] unless task.swimlane_id

      participants.
        filter { |p| p.swimlane_id == task.swimlane_id }.
        map(&:user).uniq.sort_by(&:id)
    end

    protected

    def participants
      referral.participants.preload(:swimlane, :user)
    end
  end
end
