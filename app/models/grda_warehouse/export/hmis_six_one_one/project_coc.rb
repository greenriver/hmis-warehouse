module GrdaWarehouse::Export::HMISSixOneOne
  class ProjectCoc < GrdaWarehouse::Import::HMISSixOneOne::ProjectCoc
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( GrdaWarehouse::Hud::ProjectCoc.hud_csv_headers(version: '6.11') )

    self.hud_key = :ProjectCoCID

    belongs_to :project_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Project.name, primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :project_cocs

    def apply_overrides row, data_source_id:
      if override = coc_code_override_for(project_coc_id: row[:ProjectCoCID].to_i, data_source_id: data_source_id)
        row[:CoCCode] = override
      end
      return row
    end

    def coc_code_override_for project_coc_id:, data_source_id:
      @coc_code_overrides ||= self.class.where.not(hud_coc_code: nil).
        pluck(:data_source_id, :id, :hud_coc_code).
        map do |data_source_id, project_coc_id, hud_coc_code|
          if hud_coc_code.present?
            [[data_source_id, project_coc_id], hud_coc_code]
          else
            nil
          end
        end.compact.to_h
      @coc_code_overrides[[data_source_id, project_coc_id]]
    end
  end
end