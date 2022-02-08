###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
