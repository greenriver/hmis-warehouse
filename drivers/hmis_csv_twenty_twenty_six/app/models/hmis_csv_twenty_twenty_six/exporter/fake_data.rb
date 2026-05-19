###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Exporter
  class FakeData
    include ::HmisCsvTwentyTwentySix::Exporter::ExportConcern

    def initialize(options)
      @options = options
    end

    # row is a HashWithIndifferentAccess at this point, not an AR object.
    # See ExportConcern#process for where the conversion happens.
    def process(row)
      export = @options[:export]
      return row unless export.faked_pii

      export.fake_data.fake_patterns.each_key do |k|
        next if row[k].blank?

        row[k] = export.fake_data.fetch(field_name: k, real_value: row[k])
      end
      row
    end
  end
end
