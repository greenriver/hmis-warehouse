###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
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
      GrdaWarehouse::Chronic,
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