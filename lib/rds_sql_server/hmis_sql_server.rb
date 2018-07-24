require_relative 'sql_server_base'
module HmisSqlServer

  # a Hash mapping hud filenames to GrdaWarehouse::Hud models
  module_function def models_by_hud_filename
    # use an explict whitelist as a security measure
    {
      'Affiliation.csv' => HmisSqlServer::Affiliation,
      'Client.csv' => HmisSqlServer::Client,
      'Disabilities.csv' => HmisSqlServer::Disability,
      'EmploymentEducation.csv' => HmisSqlServer::EmploymentEducation,
      'Enrollment.csv' => HmisSqlServer::Enrollment,
      'EnrollmentCoC.csv' => HmisSqlServer::EnrollmentCoc,
      'Exit.csv' => HmisSqlServer::Exit,
      'Export.csv' => HmisSqlServer::Export,
      'Funder.csv' => HmisSqlServer::Funder,
      'HealthAndDV.csv' => HmisSqlServer::HealthAndDv,
      'IncomeBenefits.csv' => HmisSqlServer::IncomeBenefit,
      'Inventory.csv' => HmisSqlServer::Inventory,
      'Organization.csv' => HmisSqlServer::Organization,
      'Project.csv' => HmisSqlServer::Project,
      'ProjectCoC.csv' => HmisSqlServer::ProjectCoc,
      'Services.csv' => HmisSqlServer::Service,
      'Geography.csv' => HmisSqlServer::Geography,
    }.freeze
  end

  class Affiliation < SqlServerBase
    self.table_name = :hmis_Affiliation
    include TsqlImport

  end

  class Client < SqlServerBase
    self.table_name = :hmis_Client
    include TsqlImport

  end

  class Disability < SqlServerBase
    self.table_name = :hmis_Disabilities
    include TsqlImport

  end
  class EmploymentEducation < SqlServerBase
    self.table_name = :hmis_EmploymentEducation
    include TsqlImport

  end
  class Enrollment < SqlServerBase
    self.table_name = :hmis_Enrollment
    include TsqlImport

  end
  class EnrollmentCoc < SqlServerBase
    self.table_name = :hmis_EnrollmentCoC
    include TsqlImport

  end
  class Exit < SqlServerBase
    self.table_name = :hmis_Exit
    include TsqlImport

  end
  class Export < SqlServerBase
    self.table_name = :hmis_Export
    include TsqlImport

  end
  class Funder < SqlServerBase
    self.table_name = :hmis_Funder
    include TsqlImport

  end
  class HealthAndDv < SqlServerBase
    self.table_name = :hmis_HealthAndDV
    include TsqlImport

  end
  class IncomeBenefit < SqlServerBase
    self.table_name = :hmis_IncomeBenefits
    include TsqlImport

  end
  class Inventory < SqlServerBase
    self.table_name = :hmis_Inventory
    include TsqlImport

  end
  class Organization < SqlServerBase
    self.table_name = :hmis_Organization
    include TsqlImport

  end
  class Project < SqlServerBase
    self.table_name = :hmis_Project
    include TsqlImport

  end
  class ProjectCoc < SqlServerBase
    self.table_name = :hmis_ProjectCoC
    include TsqlImport

  end
  class Service < SqlServerBase
    self.table_name = :hmis_Services
    include TsqlImport

  end
  class Geography < SqlServerBase
    self.table_name = :hmis_Geography
    include TsqlImport

  end
end