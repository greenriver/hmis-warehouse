###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Exporter
  class User < GrdaWarehouse::Import::HmisTwentyTwenty::User
    include ::HmisCsvTwentyTwenty::Exporter::Shared
    setup_hud_column_access(GrdaWarehouse::Hud::User.hud_csv_headers(version: '2020'))

    self.hud_key = :UserID

    # NOTE: because there is no direct connection to the scopes for all
    # exported models, we'll just gather the unique UserIDs while we're processing.
    def export! project_scope:, path:, export: # rubocop:disable Lint/UnusedMethodArgument
      export_scope = self.class.where(id: export.user_ids.to_a)
      export_to_path(
        export_scope: export_scope,
        path: path,
        export: export,
      )
    end
  end
end
