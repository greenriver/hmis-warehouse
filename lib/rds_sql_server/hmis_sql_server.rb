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

  class LsaBase  < SqlServerBase
    include TsqlImport

    def clean_row_for_import row:, headers:
      # replace blanks with nil
      row.map(&:presence)
    end
  end

  class Affiliation < LsaBase
    self.table_name = :hmis_Affiliation

  end

  class Client < LsaBase
    self.table_name = :hmis_Client

  end

  class Disability < LsaBase
    self.table_name = :hmis_Disabilities

  end
  class EmploymentEducation < LsaBase
    self.table_name = :hmis_EmploymentEducation

  end
  class Enrollment < LsaBase
    self.table_name = :hmis_Enrollment

  end
  class EnrollmentCoc < LsaBase
    self.table_name = :hmis_EnrollmentCoC

  end
  class Exit < LsaBase
    self.table_name = :hmis_Exit

  end
  class Export < LsaBase
    self.table_name = :hmis_Export

  end
  class Funder < LsaBase
    self.table_name = :hmis_Funder

  end
  class HealthAndDv < LsaBase
    self.table_name = :hmis_HealthAndDV

  end
  class IncomeBenefit < LsaBase
    self.table_name = :hmis_IncomeBenefits

  end
  class Inventory < LsaBase
    self.table_name = :hmis_Inventory

  end
  class Organization < LsaBase
    self.table_name = :hmis_Organization

  end
  class Project < LsaBase
    self.table_name = :hmis_Project

    def clean_row_for_import row:, headers:
      # Default to no for VictimServicesProvider
      field_index = headers.index('VictimServicesProvider')
      row[field_index] = row[field_index].presence || 0
      super(row: row, headers: headers)
    end

  end
  class ProjectCoc < LsaBase
    self.table_name = :hmis_ProjectCoC

  end
  class Service < LsaBase
    self.table_name = :hmis_Services

  end
  class Geography < LsaBase
    self.table_name = :hmis_Geography

  end
end