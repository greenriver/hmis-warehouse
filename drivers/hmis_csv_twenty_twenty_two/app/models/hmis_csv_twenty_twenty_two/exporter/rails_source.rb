###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class RailsSource
    def initialize(scope)
      @scope = scope
    end

    def each
      @scope.find_each(batch_size: 10_000) do |row|
        yield(row)
      end
    end
  end
end
