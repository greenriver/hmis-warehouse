###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
      GrdaWarehouse::CensusByProject,
      GrdaWarehouse::Census::ByProject,
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
      GrdaWarehouse::Hud::CeParticipation,
      GrdaWarehouse::Hud::HmisParticipation,
      GrdaWarehouse::Hud::Geography,
      GrdaWarehouse::Hud::Assessment,
      GrdaWarehouse::Hud::CurrentLivingSituation,
      GrdaWarehouse::Hud::AssessmentQuestion,
      GrdaWarehouse::Hud::AssessmentResult,
      GrdaWarehouse::Hud::Event,
      GrdaWarehouse::Hud::YouthEducationStatus,
      GrdaWarehouse::Hud::User,
      GrdaWarehouse::Hud::Export,
      GrdaWarehouse::Hud::HmisParticipation,
      GrdaWarehouse::Hud::CeParticipation,
      GrdaWarehouse::ClientMatch,
      GrdaWarehouse::ImportLog,
      GrdaWarehouse::IdentifyDuplicatesLog,
      GrdaWarehouse::GenerateServiceHistoryLog,
      GrdaWarehouse::Hud::Client,
      GrdaWarehouse::DataSource,
      GrdaWarehouse::WarehouseReports::Project::DataQuality::Base,
      GrdaWarehouse::WarehouseReports::Base,
      GrdaWarehouse::Cohort,
      GrdaWarehouse::CohortClientChange,
      Reporting::MonthlyReports::Base,
      Reporting::DataQualityReports::Enrollment,
      Reporting::DataQualityReports::Project,
      Reporting::DataQualityReports::ProjectGroup,
      Reporting::Housed,
      Reporting::MonthlyClientIds,
      Reporting::Return,
      GrPaperTrail::Version,
      GrdaWarehouse::Version,
      ReportResult,
      AccessGroup, # TODO: START_ACL remove after permission transition
      AccessGroupMember, # TODO: START_ACL remove after permission transition
      Collection,
      UserGroupMember,
      UserGroup,
      AccessControl,
      HudReports::ReportInstance,
      HudReports::UniverseMember,
      HudReports::ReportCell,
      GrdaWarehouse::WarehouseReports::ReportDefinition,
      HmisCsvValidation::Validation,
      GrdaWarehouse::Synthetic::Event,
      GrdaWarehouse::CustomImports::ImportFile,
      GrdaWarehouse::Upload,
      HomelessSummaryReport::Client,
      HomelessSummaryReport::Result,
      HmisCsvImporter::Importer::ImporterLog,
      HapReport::HapClient,
      SimpleReports::ReportCell,
      SimpleReports::UniverseMember,
      GrdaWarehouse::WhitelistedProjectsForClients,
      HmisCsvImporter::HmisCsvValidation::Base,
      GrdaWarehouse::Upload,
      HmisCsvImporter::Loader::LoaderLog,
      GrdaWarehouse::ImportLog,
      GrdaWarehouse::GroupViewableEntity,
      GrdaWarehouse::UserViewableEntity,
      ActiveStorage::Attachment,
      ActiveStorage::Blob,
      GrdaWarehouse::File,
      GrdaWarehouse::Config,
    ]
    if RailsDrivers.loaded.include?(:hud_apr)
      tables << HudApr::Fy2020::AprClient
      tables << HudApr::Fy2020::AprLivingSituation
      tables << HudApr::Fy2020::CeAssessment
      tables << HudApr::Fy2020::CeEvent
    end

    tables << HudPathReport::Fy2020::PathClient if RailsDrivers.loaded.include?(:hud_path_report)
    if RailsDrivers.loaded.include?(:hud_spm_report)
      tables << HudSpmReport::Fy2020::SpmClient
      tables << HudSpmReport::Fy2023::SpmEnrollment
      tables << HudSpmReport::Fy2023::Episode
      tables << HudSpmReport::Fy2023::BedNight
      tables << HudSpmReport::Fy2023::EnrollmentLink
      tables << HudSpmReport::Fy2023::Return
    end

    if RailsDrivers.loaded.include?(:hud_data_quality_report)
      tables << HudDataQualityReport::Fy2020::DqClient
      tables << HudDataQualityReport::Fy2020::DqLivingSituation
    end

    if RailsDrivers.loaded.include?(:performance_measurement)
      tables << PerformanceMeasurement::Report
      tables << PerformanceMeasurement::Client
      tables << PerformanceMeasurement::Project
      tables << PerformanceMeasurement::Goal
      tables << PerformanceMeasurement::Result
      tables << PerformanceMeasurement::StaticSpm
      tables << PerformanceMeasurement::PitCount
      tables << PerformanceMeasurement::ClientProject
    end

    tables << CustomImportsBostonService::Row if RailsDrivers.loaded.include?(:custom_imports_boston_services)

    if RailsDrivers.loaded.include?(:cas_ce_data)
      tables << CasCeData::GrdaWarehouse::CasReferralEvent
      tables << CasCeData::Synthetic::Assessment
    end

    tables << SyntheticCeAssessment::ProjectConfig if RailsDrivers.loaded.include?(:synthetic_ce_assessment)

    HmisCsvImporter::Utility.clear! if RailsDrivers.loaded.include?(:hmis_csv_importer)

    # Remove reports after associated clients
    tables << HudReports::ReportInstance
    tables << SimpleReports::ReportInstance

    tables.each do |model|
      manager = GrdaWarehouse::ModelTableManager.new(model)
      manager.truncate_table(modifier: modifier(model))
    end
    # fix_sequences

    # reset pks after truncation due to cascade side-effects
    tables.each do |model|
      # assign staggered pk sequence values for all tables. Staggered pk values reduce the chances of lock-step ids
      # between tables to better identify bugs related to mis-use of ids
      manager = GrdaWarehouse::ModelTableManager.new(model)
      manager.next_pk_sequence = (Zlib.crc32(model.name) + 100) % 1_000_000
    end

    # Clear the materialized view
    GrdaWarehouse::ServiceHistoryServiceMaterialized.rebuild!

    # Delete any delayed jobs, they have lost their data anyway
    Delayed::Job.delete_all
    nil
  end

  # Tool to reset postgres sequences, which occasionally get out of sync when restoring a database, dependent on restore method.
  def self.fix_sequences
    query = <<~SQL
      SELECT 'SELECT SETVAL(' ||
        quote_literal(quote_ident(PGT.schemaname) || '.' || quote_ident(S.relname)) ||
        ', COALESCE(MAX(' ||quote_ident(C.attname)|| '), 1) ) FROM ' ||
        quote_ident(PGT.schemaname)|| '.'||quote_ident(T.relname)|| ';'
      FROM pg_class AS S,
          pg_depend AS D,
          pg_class AS T,
          pg_attribute AS C,
          pg_tables AS PGT
      WHERE S.relkind = 'S'
          AND S.oid = D.objid
          AND D.refobjid = T.oid
          AND D.refobjid = C.attrelid
          AND D.refobjsubid = C.attnum
          AND T.relname = PGT.tablename
      ORDER BY S.relname;
    SQL
    result = GrdaWarehouseBase.connection.select_all(query)
    result.rows.flatten.each do |q|
      GrdaWarehouseBase.connection.execute(q)
    end
  end

  def self.modifier(model)
    cascade_models = [
      GrdaWarehouse::DataSource,
      GrdaWarehouse::Hud::Client,
      GrdaWarehouse::Hud::Project,
      GrdaWarehouse::ServiceHistoryEnrollment,
      ActiveStorage::Attachment,
      ActiveStorage::Blob,
    ]
    return 'CASCADE' if cascade_models.include?(model)

    'RESTRICT'
  end
end
