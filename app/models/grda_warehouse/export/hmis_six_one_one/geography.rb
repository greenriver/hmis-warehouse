module GrdaWarehouse::Export::HMISSixOneOne
  class Geography < GrdaWarehouse::Import::HMISSixOneOne::Geography
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( GrdaWarehouse::Hud::Geography.hud_csv_headers(version: '6.11') )

    self.hud_key = :GeographyID

    belongs_to :project_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Project.name, primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :geographies

    def apply_overrides row, data_source_id:
      if override = geography_type_override_for(geography_id: row[:GeographyID].to_i, data_source_id: data_source_id)
        row[:GeographyType] = override
      end

      if override = geocode_override_for(geography_id: row[:GeographyID].to_i, data_source_id: data_source_id)
        row[:Geocode] = override
      end

      if override = information_date_override_for(geography_id: row[:GeographyID].to_i, data_source_id: data_source_id)
        row[:InformationDate] = override
      end
      # Technical limit of HMIS spec is 50 characters
      row[:Address1] = row[:Address1][0...50] if row[:Address1]
      row[:Address2] = row[:Address2][0...50] if row[:Address2]
      row[:City] = row[:City][0...50] if row[:City]
      row[:ZIP] = row[:ZIP][0...5] if row[:ZIP]
      return row
    end

    def geography_type_override_for geography_id:, data_source_id:
      @geography_type_overrides ||= self.class.where.not(geography_type_override: nil).
        pluck(:data_source_id, :id, :geography_type_override).
        map do |data_source_id, geography_id, geography_type_override|
          if geography_type_override.present?
            [[data_source_id, geography_id], geography_type_override]
          else
            nil
          end
        end.compact.to_h
      @geography_type_overrides[[data_source_id, geography_id]]
    end

    def geocode_override_for geography_id:, data_source_id:
      @geocode_overrides ||= self.class.where.not(geocode_override: nil).
        pluck(:data_source_id, :id, :geocode_override).
        map do |data_source_id, geography_id, geocode_override|
          if geocode_override.present?
            [[data_source_id, geography_id], geocode_override]
          else
            nil
          end
        end.compact.to_h
      @geocode_overrides[[data_source_id, geography_id]]
    end

    def information_date_override_for geography_id:, data_source_id:
      @information_date_overrides ||= self.class.where.not(information_date_override: nil).
        pluck(:data_source_id, :id, :information_date_override).
        map do |data_source_id, geography_id, information_date_override|
          if information_date_override.present?
            [[data_source_id, geography_id], information_date_override]
          else
            nil
          end
        end.compact.to_h
      @information_date_overrides[[data_source_id, geography_id]]
    end
  end
end