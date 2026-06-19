###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentyFour::Exporter
  class FakeData
    include ::HmisCsvTwentyTwentyFour::Exporter::ExportConcern

    def initialize(options)
      @options = options
    end

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
