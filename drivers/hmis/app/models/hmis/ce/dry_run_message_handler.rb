# frozen_string_literal: true

# This is the MessageHandler dependency that's injected into the CE Workflow Execution Engine when it's being run
# in "dry-run" mode. In dry-run mode we don't want to save any changes to the DB, just collect and report on which
# changes WOULD be made.
module Hmis::Ce
  class DryRunMessageHandler
    attr_reader :collected_messages
    def initialize
      @collected_messages = []
    end

    def call(message)
      collected_messages.push(message)
    end
  end
end
