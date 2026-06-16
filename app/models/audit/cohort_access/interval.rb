###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Audit
  module CohortAccess
    # A half-open time interval [start_at, end_at). A nil end_at means "still open" (extends to now/forever).
    Interval = Struct.new(:start_at, :end_at) do
      def covers?(time)
        return false if time < start_at

        end_at.nil? || time < end_at
      end
    end
  end
end
