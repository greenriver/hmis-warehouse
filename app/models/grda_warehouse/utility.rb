###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
      GrdaWarehouse::ProjectGroup,
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
      GrdaWarehouse::Hud::YouthEducationStatus,
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
      AccessGroup,
      AccessGroupMember,
      HudReports::ReportInstance,
      HudReports::UniverseMember,
      HudReports::ReportCell,
      GrdaWarehouse::WarehouseReports::ReportDefinition,
      HmisCsvValidation::Validation,
    ]
    if RailsDrivers.loaded.include?(:hud_apr)
      tables << HudApr::Fy2020::AprClient
      tables << HudApr::Fy2020::AprLivingSituation
      tables << HudApr::Fy2020::CeAssessment
      tables << HudApr::Fy2020::CeEvent
    end

    tables << HudPathReport::Fy2020::PathClient if RailsDrivers.loaded.include?(:hud_path_report)
    tables << HudSpmReport::Fy2020::SpmClient if RailsDrivers.loaded.include?(:hud_spm_report)

    if RailsDrivers.loaded.include?(:hud_data_quality_report)
      tables << HudDataQualityReport::Fy2020::DqClient
      tables << HudDataQualityReport::Fy2020::DqLivingSituation
    end

    # Remove reports after associated clients
    tables << HudReports::ReportInstance
    tables << SimpleReports::ReportInstance

    tables.each do |klass|
      klass.connection.execute("TRUNCATE TABLE #{klass.quoted_table_name} #{modifier(klass)}")
    end

    nil
  end

  def self.modifier(model)
    cascade_models = [
      GrdaWarehouse::DataSource,
      GrdaWarehouse::Hud::Client,
      GrdaWarehouse::ServiceHistoryEnrollment,
    ]
    return 'CASCADE' if cascade_models.include?(model)

    'RESTRICT'
  end
end
