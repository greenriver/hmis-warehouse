class MoveExistingOverrides < ActiveRecord::Migration[6.1]
  def up
    p_t = GrdaWarehouse::Hud::Project.arel_table
    {
      act_as_project_type: :ProjectType,
      # hud_continuum_funded: :ContinuumProject,
      housing_type_override: :HousingType,
      operating_start_date_override: :OperatingStartDate,
      operating_end_date_override: :OperatingEndDate,
      hmis_participating_project_override: :HMISParticipatingProject,
      target_population_override: :TargetPopulation,
    }.each do |override, source|
      GrdaWarehouse::Hud::Project.where.not(override => nil).each do |project|
        HmisCsvImporter::ImportOverride.where(
          file_name: 'Project.csv',
          matched_hud_key: project.ProjectID,
          replaces_column: source,
          replacement_value: project[override],
          data_source_id: project.data_source_id,
        ).first_or_create
      end
    end
    # Special case Continuum Project
    GrdaWarehouse::Hud::Project.where(hud_continuum_funded: true).each do |project|
      HmisCsvImporter::ImportOverride.where(
        file_name: 'Project.csv',
        matched_hud_key: project.ProjectID,
        replaces_column: :ContinuumProject,
        replacement_value: 1,
        data_source_id: project.data_source_id,
      ).first_or_create
    end
    GrdaWarehouse::Hud::Project.where(hud_continuum_funded: false).each do |project|
      HmisCsvImporter::ImportOverride.where(
        file_name: 'Project.csv',
        matched_hud_key: project.ProjectID,
        replaces_column: :ContinuumProject,
        replacement_value: 0,
        data_source_id: project.data_source_id,
      ).first_or_create
    end

    i_t = GrdaWarehouse::Hud::Inventory.arel_table
    {
      coc_code_override: :CoCCode,
      inventory_start_date_override: :InventoryStartDate,
      inventory_end_date_override: :InventoryEndDate,
    }.each do |override, source|
      GrdaWarehouse::Hud::Inventory.where.not(override => nil).each do |inventory|
        HmisCsvImporter::ImportOverride.where(
          file_name: 'Inventory.csv',
          matched_hud_key: inventory.InventoryID,
          replaces_column: source,
          replacement_value: inventory[override],
          data_source_id: inventory.data_source_id,
        ).first_or_create
      end
    end

    pc_t = GrdaWarehouse::Hud::ProjectCoc.arel_table
    {
      hud_coc_code: :CoCCode,
      geography_type_override: :GeographyType,
      geocode_override: :Geocode,
      zip_override: :Zip,
    }.each do |override, source|
      GrdaWarehouse::Hud::ProjectCoc.where.not(override => nil).each do |project_coc|
        HmisCsvImporter::ImportOverride.where(
          file_name: 'ProjectCoC.csv',
          matched_hud_key: project_coc.ProjectCoCID,
          replaces_column: source,
          replacement_value: project_coc[override],
          data_source_id: project_coc.data_source_id,
        ).first_or_create
      end
    end
  end
end
