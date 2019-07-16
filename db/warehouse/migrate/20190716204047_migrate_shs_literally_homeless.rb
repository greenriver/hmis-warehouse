class MigrateShsLiterallyHomeless < ActiveRecord::Migration
  def change
    GrdaWarehouse::ServiceHistoryService.
      in_project_type(GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES).
      update_all(literally_homeless: true)

    s_t = GrdaWarehouse::ServiceHistoryService.arel_table
    e_t = GrdaWarehouse::Hud::Enrollment.arel_table
    GrdaWarehouse::ServiceHistoryService.
      joins(service_history_enrollment: :enrollment).
      in_project_type(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph] + GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:th]).
      where(s_t[:date].lt(e_t[:MoveInDate]).or(e_t[:MoveInDate].eq(nil))).
      update_all(literally_homeless: true)
  end
end
