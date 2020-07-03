class RemoveBiViews < ActiveRecord::Migration[5.2]
  HUD_CSV_VERSION = '2020'
  NAMESPACE = 'bi'
  PG_ROLE = 'bi'
  SH_INTERVAL = '\'5 years\'::interval'
  DEMOGRAPHICS_VIEW = "\"#{NAMESPACE}_Demographics\""

  def safe_drop_view(name)
    sql = "DROP VIEW IF EXISTS #{name}"
    say_with_time sql do
      GrdaWarehouseBase.connection.execute sql
    end
  end

  def view_name(model)
    "\"#{NAMESPACE}_#{model.table_name}\""
  end

  def change
    safe_drop_view view_name(GrdaWarehouse::Hud::Service)
    safe_drop_view view_name(GrdaWarehouse::Hud::Exit)
    safe_drop_view view_name(GrdaWarehouse::Hud::EnrollmentCoc)
    safe_drop_view view_name(GrdaWarehouse::Hud::Disability)
    safe_drop_view view_name(GrdaWarehouse::Hud::HealthAndDv)
    safe_drop_view view_name(GrdaWarehouse::Hud::IncomeBenefit)
    safe_drop_view view_name(GrdaWarehouse::Hud::EmploymentEducation)
    safe_drop_view view_name(GrdaWarehouse::Hud::CurrentLivingSituation)
    safe_drop_view view_name(GrdaWarehouse::Hud::Event)
    safe_drop_view view_name(GrdaWarehouse::Hud::Assessment)
    safe_drop_view view_name(GrdaWarehouse::Hud::AssessmentQuestion)
    safe_drop_view view_name(GrdaWarehouse::Hud::AssessmentResult)

    safe_drop_view view_name(GrdaWarehouse::Hud::Enrollment)

    safe_drop_view view_name(GrdaWarehouse::Hud::Client)
    safe_drop_view DEMOGRAPHICS_VIEW

    safe_drop_view view_name(GrdaWarehouse::Hud::Funder)
    safe_drop_view view_name(GrdaWarehouse::Hud::Inventory)
    safe_drop_view view_name(GrdaWarehouse::Hud::Export)
    safe_drop_view view_name(GrdaWarehouse::Hud::Affiliation)
    safe_drop_view view_name(GrdaWarehouse::Hud::ProjectCoc)
    safe_drop_view view_name(GrdaWarehouse::Hud::Project)
    safe_drop_view view_name(GrdaWarehouse::Hud::Organization)
    safe_drop_view view_name(GrdaWarehouse::ServiceHistoryEnrollment)
    safe_drop_view view_name(GrdaWarehouse::ServiceHistoryService)
  end
end
