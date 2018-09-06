module GrdaWarehouse::Export::HMISSixOneOne
  class Project < GrdaWarehouse::Import::HMISSixOneOne::Project
    include ::Export::HMISSixOneOne::Shared

    setup_hud_column_access( GrdaWarehouse::Hud::Project.hud_csv_headers(version: '6.11') )

    self.hud_key = :ProjectID

    belongs_to :organization_with_delted, class_name: GrdaWarehouse::Hud::WithDeleted::Organization.name, primary_key: [:OrganizationID, :data_source_id], foreign_key: [:OrganizationID, :data_source_id]

    def export! project_scope:, path:, export:
      case export.period_type
      when 3
        export_scope = project_scope
      when 1
        export_scope = project_scope.
          modified_within_range(range: (export.start_date..export.end_date))
      end

      export_to_path(
        export_scope: export_scope,
        path: path,
        export: export
      )
    end

    def apply_overrides row, data_source_id:
      if override = housing_type_override_for(project_id: row[:ProjectID].to_i, data_source_id: data_source_id)
        row[:HousingType] = override
      end
      if override = continuum_project_override_for(project_id: row[:ProjectID].to_i, data_source_id: data_source_id)
        row[:ContinuumProject] = override
      end
      row[:ContinuumProject] = row[:ContinuumProject].presence || 0

      if override = operating_start_date_override_for(project_id: row[:ProjectID].to_i, data_source_id: data_source_id)
        row[:OperatingStartDate] = override
      end
      row[:ProjectCommonName] = row[:ProjectName] if row[:ProjectCommonName].blank?

      if override = project_type_override_for(project_id: row[:ProjectID].to_i, data_source_id: data_source_id)
        row[:ProjecType] = override
      end)

      return row
    end

    def housing_type_override_for project_id:, data_source_id:
      @housing_type_overrides ||= self.class.where.not(housing_type_override: nil).
        pluck(:data_source_id, :id, :housing_type_override).
        map do |data_source_id, project_id, housing_type_override|
          if housing_type_override.present?
            [[data_source_id, project_id], housing_type_override]
          else
            nil
          end
        end.compact.to_h
      @housing_type_overrides[[data_source_id, project_id]]
    end

    def continuum_project_override_for project_id:, data_source_id:
      @continuum_project_overrides ||= self.class.where.not(hud_continuum_funded: nil).
        pluck(:data_source_id, :id, :hud_continuum_funded).
        map do |data_source_id, project_id, hud_continuum_funded|
          if hud_continuum_funded.present?
            [[data_source_id, project_id], hud_continuum_funded]
          else
            nil
          end
        end.compact.to_h
      return 1 if @continuum_project_overrides[[data_source_id, project_id]]
      return nil
    end

    def operating_start_date_override_for project_id:, data_source_id:
      @operating_start_date_overrides ||= self.class.where.not(operating_start_date_override: nil).
        pluck(:data_source_id, :id, :operating_start_date_override).
        map do |data_source_id, project_id, operating_start_date_override|
          if operating_start_date_override.present?
            [[data_source_id, project_id], operating_start_date_override]
          else
            nil
          end
        end.compact.to_h
      @operating_start_date_overrides[[data_source_id, project_id]]
    end

    def project_type_override_for project_id:, data_source_id:
      return nil unless GrdaWarehouse::Config.get(:project_type_override)
      @project_type_overrides ||= self.class.where.not(computed_project_type: nil).
        pluck(:data_source_id, :id, :computed_project_type).
        map do |data_source_id, project_id, computed_project_type|
          if computed_project_type.present?
            [[data_source_id, project_id], computed_project_type]
          else
            nil
          end
        end.compact.to_h
      @project_type_overrides[[data_source_id, project_id]]
    end
  end
end