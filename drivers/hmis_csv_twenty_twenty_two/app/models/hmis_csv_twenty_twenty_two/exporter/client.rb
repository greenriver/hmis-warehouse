###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class Client
    include ::HmisCsvTwentyTwentyTwo::Exporter::ExportConcern

    def initialize(options)
      @options = options
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
        HmisCsvTwentyTwentyTwo::Exporter::Client::Overrides,
        HmisCsvTwentyTwentyTwo::Exporter::Client,
        HmisCsvTwentyTwentyTwo::Exporter::FakeData,
      ]
    end
  end
end
