###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class User
    def initialize(options)
      @options = options
    end

    def process(row)
      row = self.class.adjust_keys(row)

      row
    end

    def self.adjust_keys(row)
      row.UserID = row.id

      row
    end

    def self.export_scope(export:, hmis_class:, **_)
      hmis_class.where(id: export.user_ids.to_a)
    end

    def self.transforms
      [
        HmisCsvTwentyTwentyTwo::Exporter::FakeData,
        HmisCsvTwentyTwentyTwo::Exporter::User,
      ]
    end
  end
end
