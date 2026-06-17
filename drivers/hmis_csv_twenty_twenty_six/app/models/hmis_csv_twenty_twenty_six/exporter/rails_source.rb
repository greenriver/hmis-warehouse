###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Exporter
  class RailsSource
    def initialize(scope)
      @scope = scope
    end

    def each
      # Keep smaller batches for development to exercise batches
      batch_size = if Rails.env.development? then 1_000 else 10_000 end
      @scope.find_each(batch_size: batch_size) do |row|
        yield(row)
      end
    end
  end
end
