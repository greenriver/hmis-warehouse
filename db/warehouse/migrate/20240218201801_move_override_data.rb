class MoveOverrideData < ActiveRecord::Migration[6.1]
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
      GrdaWarehouse::Hud::Project.where.not(override => nil).
        update_all(source => p_t[override])
    end
    # Special case Continuum Project
    GrdaWarehouse::Hud::Project.where(hud_continuum_funded: true).update_all(ContinuumProject: 1)
    GrdaWarehouse::Hud::Project.where(hud_continuum_funded: false).update_all(ContinuumProject: 0)

    i_t = GrdaWarehouse::Hud::Inventory.arel_table
    {
      coc_code_override: :CoCCode,
      inventory_start_date_override: :InventoryStartDate,
      inventory_end_date_override: :InventoryEndDate,
    }.each do |override, source|
      GrdaWarehouse::Hud::Inventory.where.not(override => nil).
        update_all(source => i_t[override])
    end

    pc_t = GrdaWarehouse::Hud::ProjectCoc.arel_table
    {
      hud_coc_code: :CoCCode,
      geography_type_override: :GeographyType,
      geocode_override: :Geocode,
      zip_override: :Zip,
    }.each do |override, source|
      GrdaWarehouse::Hud::ProjectCoc.where.not(override => nil).
        update_all(source => pc_t[override])
    end

    she_t = GrdaWarehouse::ServiceHistoryEnrollment.arel_table
    {
      computed_project_type: :project_type,
    }.each do |override, source|
      GrdaWarehouse::ServiceHistoryEnrollment.where.not(override => nil).
        where(she_t[override].not_eq(she_t[source])).
        update_all(source => she_t[override])
    end
  end
end
