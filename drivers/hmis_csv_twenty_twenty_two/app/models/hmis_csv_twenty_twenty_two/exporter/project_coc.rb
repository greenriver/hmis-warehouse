###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class ProjectCoc < GrdaWarehouse::Hud::ProjectCoc
    include ::HmisCsvTwentyTwentyTwo::Exporter::Shared
    setup_hud_column_access(GrdaWarehouse::Hud::ProjectCoc.hud_csv_headers(version: '2022'))

    belongs_to :project_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Project', primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :project_cocs

    def apply_overrides(row, data_source_id:)
      override = coc_code_override_for(project_coc_id: row[:ProjectCoCID].to_i, data_source_id: data_source_id)
      row[:CoCCode] = override if override

      override = geography_type_override_for(project_coc_id: row[:ProjectCoCID].to_i, data_source_id: data_source_id)
      row[:GeographyType] = override if override
      row[:GeographyType] = 99 if row[:GeographyType].blank?

      override = geocode_override_for(project_coc_id: row[:ProjectCoCID].to_i, data_source_id: data_source_id)
      row[:Geocode] = override if override

      override = zip_override_for(project_coc_id: row[:ProjectCoCID].to_i, data_source_id: data_source_id)
      row[:Zip] = override if override

      # Technical limit of HMIS spec is 50 characters
      row[:Address1] = row[:Address1][0...100] if row[:Address1]
      row[:Address2] = row[:Address2][0...100] if row[:Address2]
      row[:City] = row[:City][0...50] if row[:City]
      row[:Zip] = row[:Zip].to_s.rjust(5, '0')[0...5] if row[:Zip]
      row[:Zip] = '0' * 5 if row[:Zip].blank?
      row[:Geocode] = '0' * 6 if row[:Geocode].blank?
      row[:UserID] = 'op-system' if row[:UserID].blank?

      row
    end

    def coc_code_override_for(project_coc_id:, data_source_id:)
      @coc_code_overrides ||= self.class.where.not(hud_coc_code: nil).
        pluck(:data_source_id, :id, :hud_coc_code).
        map do |ds_id, pc_id, hud_coc_code|
          [[ds_id, pc_id], hud_coc_code] if hud_coc_code.present?
        end.compact.to_h
      @coc_code_overrides[[data_source_id, project_coc_id]]
    end

    def geography_type_override_for(project_coc_id:, data_source_id:)
      @geography_type_overrides ||= self.class.where.not(geography_type_override: nil).
        pluck(:data_source_id, :id, :geography_type_override).
        map do |ds_id, pc_id, geography_type_override|
          [[ds_id, pc_id], geography_type_override] if geography_type_override.present?
        end.compact.to_h
      @geography_type_overrides[[data_source_id, project_coc_id]]
    end

    def geocode_override_for(project_coc_id:, data_source_id:)
      @geocode_overrides ||= self.class.where.not(geocode_override: nil).
        pluck(:data_source_id, :id, :geocode_override).
        map do |ds_id, pc_id, geocode_override|
          [[ds_id, pc_id], geocode_override] if geocode_override.present?
        end.compact.to_h
      @geocode_overrides[[data_source_id, project_coc_id]]
    end

    def zip_override_for(project_coc_id:, data_source_id:)
      @zip_overrides ||= self.class.where.not(zip_override: nil).
        pluck(:data_source_id, :id, :zip_override).
        map do |ds_id, pc_id, zip_override|
          [[ds_id, pc_id], zip_override] if zip_override.present?
        end.compact.to_h
      @zip_overrides[[data_source_id, project_coc_id]]
    end
  end
end
