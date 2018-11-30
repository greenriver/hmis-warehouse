module GrdaWarehouse::Census
  class CensusBuilder

    def create_census (start_date, end_date)
      batch_start_date = start_date.to_date
      while batch_start_date <= end_date.to_date
        # Batches are 1 month, or to the end_date if closer
        batch_end_date = [ batch_start_date + 1.years, end_date ].min

        # By Project Type
        batch_by_project_type = ProjectTypeBatch.new(batch_start_date, batch_end_date)

        # Run builder for each project type
        GrdaWarehouse::Hud::Project::PROJECT_TYPE_TITLES.keys.each do | project_type |
          batch_by_project_type.build_batch_for_project_type(project_type)
        end
        batch_by_project_type.build_project_type_independent_batch

        GrdaWarehouseBase.transaction do
          # Remove any existing census data for the batch range
          ByProjectType.delete_all(date: batch_start_date..batch_end_date)
          ByProjectTypeClient.delete_all(date: batch_start_date..batch_end_date)

          # Save the new batch
          batch_by_project_type.by_count.values.each(&:save)
          batch_by_project_type.by_client.values.each(&:save)
        

          # By Project
          batch_by_project = ProjectBatch.new(batch_start_date, batch_end_date)
          batch_by_project.build_census_batch

          # Remove any existing census data for the batch range
          ByProject.delete_all(date: batch_start_date..batch_end_date)
          ByProjectClient.delete_all(date: batch_start_date..batch_end_date)

          # Save the new batch
          batch_by_project.by_count.values.flat_map do | project |
            project.values.each(&:save)
          end
          batch_by_project.by_client.values.flat_map do | project |
            project.values.each(&:save)
          end
        end

        # Move batch forward
        batch_start_date = batch_end_date + 1.day
      end
    end
  end
end