class IndexImportTables < ActiveRecord::Migration[5.2]
  def change
    [
      HmisCsvTwentyTwenty::Importer::Export,
      HmisCsvTwentyTwenty::Importer::Organization,
      HmisCsvTwentyTwenty::Importer::Project,
      HmisCsvTwentyTwenty::Importer::Client,
      HmisCsvTwentyTwenty::Importer::Disability,
      HmisCsvTwentyTwenty::Importer::EmploymentEducation,
      HmisCsvTwentyTwenty::Importer::Enrollment,
      HmisCsvTwentyTwenty::Importer::EnrollmentCoc,
      HmisCsvTwentyTwenty::Importer::Exit,
      HmisCsvTwentyTwenty::Importer::Funder,
      HmisCsvTwentyTwenty::Importer::HealthAndDv,
      HmisCsvTwentyTwenty::Importer::IncomeBenefit,
      HmisCsvTwentyTwenty::Importer::Inventory,
      HmisCsvTwentyTwenty::Importer::ProjectCoc,
      HmisCsvTwentyTwenty::Importer::Affiliation,
      HmisCsvTwentyTwenty::Importer::Service,
      HmisCsvTwentyTwenty::Importer::CurrentLivingSituation,
      HmisCsvTwentyTwenty::Importer::Assessment,
      HmisCsvTwentyTwenty::Importer::AssessmentQuestion,
      HmisCsvTwentyTwenty::Importer::AssessmentResult,
      HmisCsvTwentyTwenty::Importer::Event,
      HmisCsvTwentyTwenty::Importer::User,
    ].each do |klass|
      add_index klass.table_name, :importer_log_id
    end
    [
      HmisCsvTwentyTwenty::Loader::Export,
      HmisCsvTwentyTwenty::Loader::Organization,
      HmisCsvTwentyTwenty::Loader::Project,
      HmisCsvTwentyTwenty::Loader::Client,
      HmisCsvTwentyTwenty::Loader::Disability,
      HmisCsvTwentyTwenty::Loader::EmploymentEducation,
      HmisCsvTwentyTwenty::Loader::Enrollment,
      HmisCsvTwentyTwenty::Loader::EnrollmentCoc,
      HmisCsvTwentyTwenty::Loader::Exit,
      HmisCsvTwentyTwenty::Loader::Funder,
      HmisCsvTwentyTwenty::Loader::HealthAndDv,
      HmisCsvTwentyTwenty::Loader::IncomeBenefit,
      HmisCsvTwentyTwenty::Loader::Inventory,
      HmisCsvTwentyTwenty::Loader::ProjectCoc,
      HmisCsvTwentyTwenty::Loader::Affiliation,
      HmisCsvTwentyTwenty::Loader::Service,
      HmisCsvTwentyTwenty::Loader::CurrentLivingSituation,
      HmisCsvTwentyTwenty::Loader::Assessment,
      HmisCsvTwentyTwenty::Loader::AssessmentQuestion,
      HmisCsvTwentyTwenty::Loader::AssessmentResult,
      HmisCsvTwentyTwenty::Loader::Event,
      HmisCsvTwentyTwenty::Loader::User,
    ].each do |klass|
      add_index klass.table_name, :loader_id
    end
  end
end
