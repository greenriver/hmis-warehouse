module Hmis::Ce
  class ReferralMessageHandler
    attr_reader :referral
    def initialize(referral)
      @referral = referral
    end

    # route the message to the appropriate handler method
    def call(message)
      # need to set move-in date on enrollment also
      case message.type
      when 'start_referral'
        start_referral
      when 'accept_referral'
        accept_referral
      when 'reject_referral'
        referral.reject!
      when 'send_notification'
        send_notification(message)
      when 'create_ce_event'
        create_ce_event(message)
      when 'create_wip_enrollment'
        create_wip_enrollment(message)
      when 'set_move_in_date'
        set_move_in_date(message)
      else
        raise "Got unhandled message type #{message.type}"
      end
    end

    protected

    def start_referral
      referral.start!
      referral.opportunity.reserve!
    end

    def accept_referral
      referral.accept!
      referral.opportunity.close!
      # TBD enroll client, set move-in date, assign to unit if needed
      # enrollment = referral.target_enrollment
      # if enrollment.nil?
      #   referral.target_enrollment ||= referral.project.enrollments.create!(client: referral.client)
      #   referral.update!(target_enrollment: enrollment)
      # else
      #   enrollment.mark-non-wip
      # end
    end

    def create_unit_assignment(message)
      # tbd
    end

    def create_wip_enrollment(_message)
      raise 'TBD'
      # enrollment = referral.project.enrollments.wip.create!(client: referral.client)
      # referral.update!(target_enrollment: enrollment)
    end

    def create_ce_event(message)
      # TBD
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
  end
end
