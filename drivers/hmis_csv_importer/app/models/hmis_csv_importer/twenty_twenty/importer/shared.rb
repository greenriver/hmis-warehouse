module HmisCsvImporter::TwentyTwenty::Importer
  module Shared
    extend ActiveSupport::Concern

    included do
      def self.importable_files
        {
          'Export.csv' => export_source,
          'Organization.csv' => organization_source,
          'Project.csv' => project_source,
          'Client.csv' => client_source,
          'Disabilities.csv' => disability_source,
          'EmploymentEducation.csv' => employment_education_source,
          'Enrollment.csv' => enrollment_source,
          'EnrollmentCoC.csv' => enrollment_coc_source,
          'Exit.csv' => exit_source,
          'Funder.csv' => funder_source,
          'HealthAndDV.csv' => health_and_dv_source,
          'IncomeBenefits.csv' => income_benefits_source,
          'Inventory.csv' => inventory_source,
          'ProjectCoC.csv' => project_coc_source,
          'Affiliation.csv' => affiliation_source,
          'Services.csv' => service_source,
          'CurrentLivingSituation.csv' => current_living_situation_source,
          'Assessment.csv' => assessment_source,
          'AssessmentQuestions.csv' => assessment_question_source,
          'AssessmentResults.csv' => assessment_result_source,
          'Event.csv' => event_source,
          'User.csv' => user_source,
        }.freeze
      end
    end
  end
end
