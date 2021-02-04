###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Export::HmisTwentyTwenty
  class Funder < GrdaWarehouse::Import::HmisTwentyTwenty::Funder
    include ::Export::HmisTwentyTwenty::Shared
    setup_hud_column_access(GrdaWarehouse::Hud::Funder.hud_csv_headers(version: '2020'))

    self.hud_key = :FunderID

    belongs_to :project_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Project', primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :funders

    def apply_overrides row, data_source_id:
      row[:GrantID] = 'Unknown' if row[:GrantID].blank?
      row[:OtherFunder] = row[:OtherFunder][0...50] if row[:OtherFunder]

      return row
    end
  end
end
