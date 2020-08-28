require_relative '../../sql_server_base'
module HmisSqlServer
  # a Hash mapping hud filenames to GrdaWarehouse::Hud models
  module_function def models_by_hud_filename
    # use an explict whitelist as a security measure
    {
      'Export.csv' => HmisSqlServer::Export,
      'Funder.csv' => HmisSqlServer::Funder,
      'Affiliation.csv' => HmisSqlServer::Affiliation,
      'Inventory.csv' => HmisSqlServer::Inventory,
      'Organization.csv' => HmisSqlServer::Organization,
      'Project.csv' => HmisSqlServer::Project,
      'ProjectCoC.csv' => HmisSqlServer::ProjectCoc,
      'User.csv' => HmisSqlServer::User,
      'Client.csv' => HmisSqlServer::Client,
      'CurrentLivingSituation.csv' => HmisSqlServer::CurrentLivingSituation,
      'Disabilities.csv' => HmisSqlServer::Disability,
      'EmploymentEducation.csv' => HmisSqlServer::EmploymentEducation,
      'Enrollment.csv' => HmisSqlServer::Enrollment,
      'EnrollmentCoC.csv' => HmisSqlServer::EnrollmentCoc,
      'Event.csv' => HmisSqlServer::Event,
      'Exit.csv' => HmisSqlServer::Exit,
      'HealthAndDV.csv' => HmisSqlServer::HealthAndDv,
      'IncomeBenefits.csv' => HmisSqlServer::IncomeBenefit,
      'Services.csv' => HmisSqlServer::Service,
      'Assessment.csv' => HmisSqlServer::Assessment,
      'AssessmentQuestions.csv' => HmisSqlServer::AssessmentQuestion,
      'AssessmentResults.csv' => HmisSqlServer::AssessmentResult,
    }.freeze
  end

  class LsaBase < SqlServerBase
    include TsqlImport

    def clean_row_for_import(row:, headers:) # rubocop:disable Lint/UnusedMethodArgument
      # replace blanks with nil
      row.map(&:presence)
    end
  end

  class Affiliation < LsaBase
    self.table_name = :hmis_Affiliation
    include ::HMIS::Structure::Affiliation
  end

  class Client < LsaBase
    self.table_name = :hmis_Client
    include ::HMIS::Structure::Client
  end

  class Disability < LsaBase
    self.table_name = :hmis_Disabilities
    include ::HMIS::Structure::Disability
  end
  class EmploymentEducation < LsaBase
    self.table_name = :hmis_EmploymentEducation
    include ::HMIS::Structure::EmploymentEducation
  end
  class Enrollment < LsaBase
    self.table_name = :hmis_Enrollment
    include ::HMIS::Structure::Enrollment
  end
  class EnrollmentCoc < LsaBase
    self.table_name = :hmis_EnrollmentCoC
    include ::HMIS::Structure::EnrollmentCoc
  end
  class Exit < LsaBase
    self.table_name = :hmis_Exit
    include ::HMIS::Structure::Exit
  end
  class Export < LsaBase
    self.table_name = :hmis_Export
    include ::HMIS::Structure::Export
  end
  class Funder < LsaBase
    self.table_name = :hmis_Funder
    include ::HMIS::Structure::Funder
  end
  class HealthAndDv < LsaBase
    self.table_name = :hmis_HealthAndDV
    include ::HMIS::Structure::HealthAndDv
  end
  class IncomeBenefit < LsaBase
    self.table_name = :hmis_IncomeBenefits
    include ::HMIS::Structure::IncomeBenefit
  end
  class Inventory < LsaBase
    self.table_name = :hmis_Inventory
    include ::HMIS::Structure::Inventory

    def clean_row_for_import(row:, headers:)
      return nil unless row[headers.index('InventoryStartDate')].present?

      # Fixes for LSA idiosyncracies
      [
        'CHVetBedInventory',
        'YouthVetBedInventory',
        'VetBedInventory',
        'CHYouthBedInventory',
        'YouthBedInventory',
        'CHBedInventory',
        'OtherBedInventory',
      ].each do |k|
        field_index = headers.index(k)
        row[field_index] = row[field_index].presence || 0
      end

      super(row: row, headers: headers)
    end
  end
  class Organization < LsaBase
    self.table_name = :hmis_Organization
    include ::HMIS::Structure::Organization
  end
  class Project < LsaBase
    self.table_name = :hmis_Project
    include ::HMIS::Structure::Project

    def clean_row_for_import(row:, headers:)
      # Fixes for LSA idiosyncracies
      [
        'HousingType',
      ].each do |k|
        field_index = headers.index(k)
        row[field_index] = row[field_index].presence || 99
      end

      super(row: row, headers: headers)
    end
  end
  class ProjectCoc < LsaBase
    self.table_name = :hmis_ProjectCoC
    include ::HMIS::Structure::ProjectCoc
  end
  class Service < LsaBase
    self.table_name = :hmis_Services
    include ::HMIS::Structure::Service
  end

  class User < LsaBase
    self.table_name = :hmis_User
    include ::HMIS::Structure::User

    def clean_row_for_import(row:, headers:)
      # Fixes for LSA idiosyncracies
      [
        'DateCreated',
        'DateUpdated',
      ].each do |k|
        field_index = headers.index(k)
        row[field_index] = row[field_index].presence || Time.current
      end

      super(row: row, headers: headers)
    end
  end
  class CurrentLivingSituation < LsaBase
    self.table_name = :hmis_CurrentLivingSituation
    include ::HMIS::Structure::CurrentLivingSituation
  end
  class Assessment < LsaBase
    self.table_name = :hmis_Assessment
    include ::HMIS::Structure::Assessment
  end
  class AssessmentQuestion < LsaBase
    self.table_name = :hmis_AssessmentQuestions
    include ::HMIS::Structure::AssessmentQuestion
  end
  class AssessmentResult < LsaBase
    self.table_name = :hmis_AssessmentResults
    include ::HMIS::Structure::AssessmentResult
  end
  class Event < LsaBase
    self.table_name = :hmis_Event
    include ::HMIS::Structure::Event
  end
end
