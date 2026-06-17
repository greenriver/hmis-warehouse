###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudTwentyTwentyToTwentyTwentyTwo::Kiba
  class RailsSource
    def initialize(klass)
      @source_class = klass
    end

    def each
      @source_class.find_in_batches do |batch|
        batch.each do |row|
          yield(row.attributes)
        end
      end
    end
  end
end
