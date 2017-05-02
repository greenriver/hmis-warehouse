class GrdaWarehouse::Utility
  def self.clear!
    GrdaWarehouse::ServiceHistory.delete_all
    GrdaWarehouse::WarehouseClientsProcessed.delete_all
    GrdaWarehouse::WarehouseClient.delete_all
    GrdaWarehouse::Hud::Affiliation.delete_all
    GrdaWarehouse::Hud::Disability.delete_all
    GrdaWarehouse::Hud::EmploymentEducation.delete_all
    GrdaWarehouse::Hud::Enrollment.delete_all
    GrdaWarehouse::Hud::EnrollmentCoc.delete_all
    GrdaWarehouse::Hud::Exit.delete_all
    GrdaWarehouse::Hud::Funder.delete_all
    GrdaWarehouse::Hud::HealthAndDv.delete_all
    GrdaWarehouse::Hud::IncomeBenefit.delete_all
    GrdaWarehouse::Hud::Service.delete_all
    GrdaWarehouse::Hud::Inventory.delete_all
    GrdaWarehouse::Hud::Organization.delete_all
    GrdaWarehouse::Hud::Project.delete_all
    GrdaWarehouse::Hud::ProjectCoc.delete_all
    GrdaWarehouse::Hud::Site.delete_all
    GrdaWarehouse::Hud::Export.delete_all
    GrdaWarehouse::Hud::Client.delete_all
  end
end