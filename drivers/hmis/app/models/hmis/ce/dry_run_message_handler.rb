# frozen_string_literal: true

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
