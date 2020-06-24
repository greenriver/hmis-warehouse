###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::Utility
  def self.clear!
    raise 'Refusing to wipe a production warehouse' if Rails.env.production?
    tables = [
      GrdaWarehouse::ServiceHistoryEnrollment,
      GrdaWarehouse::WarehouseClientsProcessed,
      GrdaWarehouse::WarehouseClient,
      GrdaWarehouse::CensusByYear,
      GrdaWarehouse::CensusByProjectType,
      GrdaWarehouse::CensusByProject,
      GrdaWarehouse::Census::ByProjectType,
      GrdaWarehouse::Census::ByProject,
      GrdaWarehouse::Census::ByProjectClient,
      GrdaWarehouse::Census::ByProjectType,
      GrdaWarehouse::Census::ByProjectTypeClient,
      GrdaWarehouse::Chronic,
      GrdaWarehouse::HudChronic,
      GrdaWarehouse::Hud::Affiliation,
      GrdaWarehouse::Hud::Disability,
      GrdaWarehouse::Hud::EmploymentEducation,
      GrdaWarehouse::Hud::Enrollment,
      GrdaWarehouse::Hud::EnrollmentCoc,
      GrdaWarehouse::Hud::Exit,
      GrdaWarehouse::Hud::Funder,
      GrdaWarehouse::Hud::HealthAndDv,
      GrdaWarehouse::Hud::IncomeBenefit,
      GrdaWarehouse::Hud::Service,
      GrdaWarehouse::Hud::Inventory,
      GrdaWarehouse::Hud::Organization,
      GrdaWarehouse::Hud::Project,
      GrdaWarehouse::Hud::ProjectCoc,
      GrdaWarehouse::Hud::Geography,
      GrdaWarehouse::Hud::Assessment,
      GrdaWarehouse::Hud::CurrentLivingSituation,
      GrdaWarehouse::Hud::AssessmentQuestion,
      GrdaWarehouse::Hud::AssessmentResult,
      GrdaWarehouse::Hud::Event,
      GrdaWarehouse::Hud::User,
      GrdaWarehouse::Hud::Export,
      GrdaWarehouse::ClientMatch,
      GrdaWarehouse::ImportLog,
      GrdaWarehouse::IdentifyDuplicatesLog,
      GrdaWarehouse::GenerateServiceHistoryLog,
      GrdaWarehouse::Hud::Client,
      GrdaWarehouse::DataSource,
      GrdaWarehouse::WarehouseReports::Project::DataQuality::Base,
      GrdaWarehouse::WarehouseReports::Base,
      GrdaWarehouse::Cohort,
      Reporting::MonthlyReports::Base,
      Reporting::DataQualityReports::Enrollment,
      Reporting::DataQualityReports::Project,
      Reporting::DataQualityReports::ProjectGroup,
      Reporting::Housed,
      Reporting::MonthlyClientIds,
      Reporting::Return,
      ReportResult,
    ]
    tables.each do |klass|
      klass.connection.execute("TRUNCATE TABLE #{klass.quoted_table_name} #{modifier(klass)}")
    end
  end
  def self.modifier(model)
    return 'CASCADE' if [GrdaWarehouse::DataSource,GrdaWarehouse::Hud::Client,GrdaWarehouse::ServiceHistoryEnrollment].include?(model)
    'RESTRICT'
  end
end