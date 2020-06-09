class CreateTwentyTwentyDataLake < ActiveRecord::Migration[5.2]
  def up
    # Unsure why, but this won't work in the context of the migration
    # HmisCsvImporter::TwentyTwenty.models_by_hud_filename.values.each do |klass|
    classes.each do |klass|
      klass.hmis_table_create!(version: '2020', constraints: false)
      klass.hmis_table_create_indices!(version: '2020')
    end
  end

  def down
    classes.each do |klass|
      drop_table klass.table_name
    end
  end

  def classes
    [
      HmisCsvImporter::TwentyTwenty::Affiliation,
      HmisCsvImporter::TwentyTwenty::Client,
      HmisCsvImporter::TwentyTwenty::CurrentLivingSituation,
      HmisCsvImporter::TwentyTwenty::Disability,
      HmisCsvImporter::TwentyTwenty::EmploymentEducation,
      HmisCsvImporter::TwentyTwenty::Enrollment,
      HmisCsvImporter::TwentyTwenty::EnrollmentCoc,
      HmisCsvImporter::TwentyTwenty::Event,
      HmisCsvImporter::TwentyTwenty::Exit,
      HmisCsvImporter::TwentyTwenty::Export,
      HmisCsvImporter::TwentyTwenty::Funder,
      HmisCsvImporter::TwentyTwenty::HealthAndDv,
      HmisCsvImporter::TwentyTwenty::IncomeBenefit,
      HmisCsvImporter::TwentyTwenty::Inventory,
      HmisCsvImporter::TwentyTwenty::Organization,
      HmisCsvImporter::TwentyTwenty::Project,
      HmisCsvImporter::TwentyTwenty::ProjectCoc,
      HmisCsvImporter::TwentyTwenty::Service,
      HmisCsvImporter::TwentyTwenty::User,
      HmisCsvImporter::TwentyTwenty::Assessment,
      HmisCsvImporter::TwentyTwenty::AssessmentQuestion,
      HmisCsvImporter::TwentyTwenty::AssessmentResult,
    ]
  end
end
