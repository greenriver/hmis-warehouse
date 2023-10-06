###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Exporter
  class Client
    include ::HmisCsvTwentyTwentyFour::Exporter::ExportConcern

    def initialize(options)
      @options = options
    end

    def process(row)
      row = self.class.adjust_keys(row)
      row = self.class.apply_overrides(row)

      row
    end

    def self.apply_overrides(row)
      row = replace_newlines(row, hud_field: :DifferentIdentityText)

      row
    end

    def self.adjust_keys(row)
      row.UserID = row.user&.id || 'op-system'
      row.PersonalID = row.id

      row
    end

    def self.export_scope(client_scope:, export:, **_)
      export_scope = case export.period_type
      when 3
        client_scope
      when 1
        client_scope.
          modified_within_range(range: (export.start_date..export.end_date))
      end
      note_involved_user_ids(scope: export_scope, export: export)

      export_scope.preload(:user, :source_clients).distinct
    end

    def self.transforms
      [
        HmisCsvTwentyTwentyFour::Exporter::Client::Overrides,
        HmisCsvTwentyTwentyFour::Exporter::Client,
        HmisCsvTwentyTwentyFour::Exporter::FakeData,
      ]
    end
  end
end
