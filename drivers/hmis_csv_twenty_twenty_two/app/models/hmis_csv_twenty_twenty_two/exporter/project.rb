###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class Project < GrdaWarehouse::Hud::Project
    include ::HmisCsvTwentyTwentyTwo::Exporter::Shared
    setup_hud_column_access(GrdaWarehouse::Hud::Project.hud_csv_headers(version: '2022'))

    belongs_to :organization_with_delted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Organization', primary_key: [:OrganizationID, :data_source_id], foreign_key: [:OrganizationID, :data_source_id]

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
        export: export,
      )
    end

    def apply_overrides row, data_source_id:
      override = housing_type_override_for(project_id: row[:ProjectID].to_i, data_source_id: data_source_id)
      row[:HousingType] = override if override.present?

      override = continuum_project_override_for(project_id: row[:ProjectID].to_i, data_source_id: data_source_id)
      row[:ContinuumProject] = override if override.present?
      row[:ContinuumProject] = row[:ContinuumProject].presence || 0

      override = operating_start_date_override_for(project_id: row[:ProjectID].to_i, data_source_id: data_source_id)
      row[:OperatingStartDate] = override if override.present?

      override = operating_end_date_override_for(project_id: row[:ProjectID].to_i, data_source_id: data_source_id)
      row[:OperatingEndDate] = override if override.present?

      row[:ProjectCommonName] = row[:ProjectName] if row[:ProjectCommonName].blank?

      override = hmis_participating_project_override_for(project_id: row[:ProjectID].to_i, data_source_id: data_source_id)
      row[:HMISParticipatingProject] = override if override.present?
      row[:HMISParticipatingProject] = 99 if row[:HMISParticipatingProject].blank?

      override = target_population_override_for(project_id: row[:ProjectID].to_i, data_source_id: data_source_id)
      row[:TargetPopulation] = override if override.present?

      # TrackingMethod override is dependent on the original ProjectType, this must come before the ProjectType override
      override = project_type_tracking_method_override_for(project: row, data_source_id: data_source_id)
      row[:TrackingMethod] = override if override.present?

      # Potentially we have an explicit override for tracking method, use that in preference to the above
      override = tracking_method_override_for(project_id: row[:ProjectID], data_source_id: data_source_id)
      row[:TrackingMethod] = override if override.present?

      override = project_type_override_for(project_id: row[:ProjectID].to_i, data_source_id: data_source_id)
      row[:ProjectType] = override if override.present?

      return row
    end

    # If we are not ES and overriding to ES, we need a tracking method of 0
    def project_type_tracking_method_override_for(project:, data_source_id:)
      return nil unless GrdaWarehouse::Config.get(:project_type_override)

      project_id = project[:ProjectID].to_i
      project_type = project[:ProjectType].to_i
      project_type_override = project_type_overrides[[data_source_id, project_id]]
      return nil unless project_type_override.present?

      es_types = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:es]
      return nil if es_types.include?(project_type)
      return 0 if es_types.include?(project_type_override)
    end

    def tracking_method_override_for(project_id:, data_source_id:)
      @tracking_method_overrides ||= self.class.where.not(tracking_method_override: nil).
        pluck(:data_source_id, :id, :tracking_method_override).
        map do |ds_id, p_id, tracking_method_override|
          [[ds_id, p_id], tracking_method_override] if tracking_method_override.present?
        end.compact.to_h
      @tracking_method_overrides[[data_source_id, project_id]]
    end

    def target_population_override_for(project_id:, data_source_id:)
      @target_population_overrides ||= self.class.where.not(target_population_override: nil).
        pluck(:data_source_id, :id, :target_population_override).
        map do |ds_id, p_id, target_population_override|
          [[ds_id, p_id], target_population_override] if target_population_override.present?
        end.compact.to_h
      @target_population_overrides[[data_source_id, project_id]]
    end

    def housing_type_override_for(project_id:, data_source_id:)
      @housing_type_overrides ||= self.class.where.not(housing_type_override: nil).
        pluck(:data_source_id, :id, :housing_type_override).
        map do |ds_id, p_id, housing_type_override|
          [[ds_id, p_id], housing_type_override] if housing_type_override.present?
        end.compact.to_h
      @housing_type_overrides[[data_source_id, project_id]]
    end

    def continuum_project_override_for(project_id:, data_source_id:)
      @continuum_project_overrides ||= self.class.where.not(hud_continuum_funded: nil).
        pluck(:data_source_id, :id, :hud_continuum_funded).
        map do |ds_id, p_id, hud_continuum_funded|
          next unless hud_continuum_funded.in?([true, false])

          override = 0
          override = 1 if hud_continuum_funded
          [[ds_id, p_id], override]
        end.compact.to_h
      return @continuum_project_overrides[[data_source_id, project_id]]
    end

    def hmis_participating_project_override_for(project_id:, data_source_id:)
      @hmis_participating_project_override_for ||= self.class.where.not(hmis_participating_project_override: nil).
        pluck(:data_source_id, :id, :hmis_participating_project_override).
        map do |ds_id, p_id, hmis_participating_project_override|
          [[ds_id, p_id], hmis_participating_project_override] if hmis_participating_project_override.present?
        end.compact.to_h
      @hmis_participating_project_override_for[[data_source_id, project_id]]
    end

    def operating_start_date_override_for(project_id:, data_source_id:)
      @operating_start_date_overrides ||= self.class.where.not(operating_start_date_override: nil).
        pluck(:data_source_id, :id, :operating_start_date_override).
        map do |ds_id, p_id, operating_start_date_override|
          [[ds_id, p_id], operating_start_date_override] if operating_start_date_override.present?
        end.compact.to_h
      @operating_start_date_overrides[[data_source_id, project_id]]
    end

    def operating_end_date_override_for(project_id:, data_source_id:)
      @operating_end_date_overrides ||= self.class.where.not(operating_end_date_override: nil).
        pluck(:data_source_id, :id, :operating_end_date_override).
        map do |ds_id, p_id, operating_end_date_override|
          [[ds_id, p_id], operating_end_date_override] if operating_end_date_override.present?
        end.compact.to_h
      @operating_end_date_overrides[[data_source_id, project_id]]
    end

    def project_type_override_for(project_id:, data_source_id:)
      return nil unless GrdaWarehouse::Config.get(:project_type_override)

      project_type_overrides[[data_source_id, project_id]]
    end

    def project_type_overrides
      @project_type_overrides ||= self.class.where.not(computed_project_type: nil).
        pluck(:data_source_id, :id, :computed_project_type).
        map do |data_source_id, project_id, computed_project_type|
          [[data_source_id, project_id], computed_project_type] if computed_project_type.present?
        end.compact.to_h
    end
  end
end
