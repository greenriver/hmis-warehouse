###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# handle workflow execution messages

module Hmis::Ce
  class ReferralMessageHandler
    ACCEPT_REFERRAL_MESSAGE = 'accept_referral'
    REJECT_REFERRAL_MESSAGE = 'reject_referral'

    # In general, when accessing `submitted_values` from the message handler, use safe accessor because:
    # - `step` could be nil, when the message is triggered by an event that doesn't involve a step, such as `start_workflow`, `end_workflow`, or `pass_gateway`.
    # - `submitted_values` could be nil, when the step hasn't been submitted yet, for example if the message is triggered by the `start_step` event

    attr_reader :referral

    def initialize(referral)
      @referral = referral
    end

    # route the message to the appropriate handler method
    def call(message)
      reversible = true

      case message.type
      when 'start_referral'
        start_referral
      when Hmis::Ce::ReferralMessageHandler::ACCEPT_REFERRAL_MESSAGE
        accept_referral
        reversible = false
      when Hmis::Ce::ReferralMessageHandler::REJECT_REFERRAL_MESSAGE
        reject_referral
        reversible = false
      when 'send_notification'
        send_notification(message)
      when 'create_ce_event'
        create_ce_event(message)
      when 'set_ce_event_result'
        set_ce_event_result(message)
      when 'create_enrollment'
        referral_enroller.create_enrollment(message)
        reversible = false
      when 'set_move_in_date'
        # Can be triggered on the same step as create_enrollment, or a later step
        referral_enroller.set_move_in_date(message)
      else
        raise "Got unhandled message type #{message.type}"
      end

      Hmis::WorkflowExecution::MessageResult.new(success?: true, reversible?: reversible)
    end

    protected

    def start_referral
      referral.start!
      referral.opportunity.reserve!
    end

    def accept_referral
      referral.completed_at = Time.current
      referral.accept!
      referral.opportunity.close!
    end

    def reject_referral
      referral.completed_at = Time.current
      referral.reject!
      referral.opportunity.release!
    end

    def create_unit_assignment(message)
      # tbd
    end

    def create_ce_event(message)
      referral_ce_event_manager.create_ce_event(message)
    end

    def set_ce_event_result(message) # rubocop:disable Naming/AccessorMethodName
      referral_ce_event_manager.set_ce_event_result(message)
    end

    def send_notification(message)
      # TBD
      #
      # Will we handle configuration here?
      # either
      #  - send 'activity occurred to case manager'
      #  - send_to email: get_users_by_role(event.config['role']), body: event.config[message]
      # NotifyUser.ce_event_notification(
      #   referral_id: self.id,
      #   user_id: event.user.id,
      # ).deliver_later
    end

    private

    def referral_enroller
      @referral_enroller ||= Hmis::Ce::ReferralEnroller.new(referral)
    end

    def referral_ce_event_manager
      @referral_ce_event_manager ||= Hmis::Ce::ReferralCeEventManager.new(referral)
    end
  end
end
