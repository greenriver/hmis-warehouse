###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvImporter
  module TwentyTwenty
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    # def self.table_name_prefix
    #   'hmis_csv_importer_twenty_twenty_'
    # end

    def self.models_by_hud_filename
      {
        'Affiliation.csv' => HmisCsvImporter::TwentyTwenty::Affiliation,
        'Client.csv' => HmisCsvImporter::TwentyTwenty::Client,
        'CurrentLivingSituation.csv' => HmisCsvImporter::TwentyTwenty::CurrentLivingSituation,
        'Disabilities.csv' => HmisCsvImporter::TwentyTwenty::Disability,
        'EmploymentEducation.csv' => HmisCsvImporter::TwentyTwenty::EmploymentEducation,
        'Enrollment.csv' => HmisCsvImporter::TwentyTwenty::Enrollment,
        'EnrollmentCoC.csv' => HmisCsvImporter::TwentyTwenty::EnrollmentCoc,
        'Event.csv' => HmisCsvImporter::TwentyTwenty::Event,
        'Exit.csv' => HmisCsvImporter::TwentyTwenty::Exit,
        'Export.csv' => HmisCsvImporter::TwentyTwenty::Export,
        'Funder.csv' => HmisCsvImporter::TwentyTwenty::Funder,
        'HealthAndDV.csv' => HmisCsvImporter::TwentyTwenty::HealthAndDv,
        'IncomeBenefits.csv' => HmisCsvImporter::TwentyTwenty::IncomeBenefit,
        'Inventory.csv' => HmisCsvImporter::TwentyTwenty::Inventory,
        'Organization.csv' => HmisCsvImporter::TwentyTwenty::Organization,
        'Project.csv' => HmisCsvImporter::TwentyTwenty::Project,
        'ProjectCoC.csv' => HmisCsvImporter::TwentyTwenty::ProjectCoc,
        'Services.csv' => HmisCsvImporter::TwentyTwenty::Service,
        'User.csv' => HmisCsvImporter::TwentyTwenty::User,
        'Assessment.csv' => HmisCsvImporter::TwentyTwenty::Assessment,
        'AssessmentQuestions.csv' => HmisCsvImporter::TwentyTwenty::AssessmentQuestion,
        'AssessmentResults.csv' => HmisCsvImporter::TwentyTwenty::AssessmentResult,
      }.freeze
    end
  end
end
