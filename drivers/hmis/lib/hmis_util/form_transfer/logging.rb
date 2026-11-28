###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  module FormTransfer
    # Expects @output to respond to #puts.
    module Logging
      private

      def log(message)
        @output.puts("  #{message}")
      end

      def log_save(record, label, validate: true)
        action = if record.new_record? then 'create'
        elsif record.changed? then 'update'
        else 'unchanged'
        end
        record.save!(validate: validate)
        log("#{action} #{label}")
      end
    end
  end
end
