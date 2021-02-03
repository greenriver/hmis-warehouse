###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Import::HmisTwentyTwenty
  class Funder < GrdaWarehouse::Hud::Funder
    include ::Import::HmisTwentyTwenty::Shared
    include TsqlImport
    self.hud_key = :FunderID
    setup_hud_column_access( GrdaWarehouse::Hud::Funder.hud_csv_headers(version: '2020') )

    def self.file_name
      'Funder.csv'
    end

    # Each import should be authoritative for funder for all projects included
    def self.delete_involved projects:, range:, data_source_id:, deleted_at:
      deleted_count = 0
      projects.each do |project|
        del_scope = self.where(ProjectID: project.ProjectID, data_source_id: data_source_id)
        deleted_count += del_scope.update_all(pending_date_deleted: deleted_at)
      end
      deleted_count
    end

  end
end
