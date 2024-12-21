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
        referral.start!
      when 'accept_referral'
        accept_referral(message)
      when 'reject_referral'
        referral.reject!
      when 'send_notification'
        send_notification(message)
      when 'create_ce_event'
        create_ce_event(message)
      else
        raise "Got unhandled message type #{message.type}"
      end
    end

    protected

    def accept_referral(_message)
      referral.accept!
      # enroll client, set move-in date
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
