###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Export::HMISSixOneOne
  class Geography < GrdaWarehouse::Import::HMISSixOneOne::Geography
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( GrdaWarehouse::Hud::Geography.hud_csv_headers(version: '6.11') )

    self.hud_key = :GeographyID

    belongs_to :project_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Project', primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :geographies

    # Geography records should be one per ProjectID per CoCCode
    def export_project_related! project_scope:, path:, export:
      case export.period_type
      when 3
        export_scope = self.class.where(project_exits_for_model(project_scope))
      when 1
        export_scope = self.class.where(project_exits_for_model(project_scope)).modified_within_range(range: (export.start_date..export.end_date))
      end
      # limit based on id order (this is somewhat arbitrary, but we need something that ensures order)
      d_t1 = GrdaWarehouse::Hud::Geography.arel_table
      d_t2 = Arel::Table.new(d_t1.table_name)
      d_t2.table_alias = 'geography_2'
      export_scope = export_scope.where(
        d_t2.project('1').where(d_t2[:DateDeleted].eq(nil)).
        where(d_t2[:ProjectID].eq(d_t1[:ProjectID])).
        where(d_t2[:CoCCode].eq(d_t1[:CoCCode])).
        where(d_t2[:data_source_id].eq(d_t1[:data_source_id])).
        where(d_t2[:id].gt(d_t1[:id])).
        exists.not
      )

      export_to_path(
        export_scope: export_scope,
        path: path,
        export: export
      )
    end

    def apply_overrides row, data_source_id:
      if override = geography_type_override_for(geography_id: row[:GeographyID].to_i, data_source_id: data_source_id)
        row[:GeographyType] = override
      end

      if override = geocode_override_for(geography_id: row[:GeographyID].to_i, data_source_id: data_source_id)
        row[:Geocode] = override
      end

      # Technical limit of HMIS spec is 50 characters
      row[:Address1] = row[:Address1][0...100] if row[:Address1]
      row[:Address2] = row[:Address2][0...100] if row[:Address2]
      row[:City] = row[:City][0...50] if row[:City]
      row[:ZIP] = row[:ZIP][0...5] if row[:ZIP]
      return row
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