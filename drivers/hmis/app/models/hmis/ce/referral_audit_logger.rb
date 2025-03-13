# frozen_string_literal: true

module Hmis::Ce
  class ReferralAuditLogger
    attr_reader :instance
    def initialize(instance)
      @instance = instance
    end

    def call(event_type, user: nil, event_data: nil, step: nil)
      instance.audit_events.create!(event_type: event_type, user: user, event_data: event_data, step: step)
    end
  end
end
