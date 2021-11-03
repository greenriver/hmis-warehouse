RSpec.shared_context '2022 project setup', shared_context: :metadata do
  let!(:data_source) { create :source_data_source, id: 2 }
  let!(:user) { create :user }
  let!(:projects) { create_list :hud_project, 5, data_source_id: data_source.id }
  let!(:organizations) { create_list :hud_organization, 5, data_source_id: data_source.id }
  let!(:inventories) { create_list :hud_inventory, 5, data_source_id: data_source.id }
  let!(:affiliations) { create_list :hud_affiliation, 5, data_source_id: data_source.id }
  let!(:project_cocs) { create_list :hud_project_coc, 5, data_source_id: data_source.id }
  let!(:funders) { create_list :hud_funder, 5, data_source_id: data_source.id }

  # Project Related
  # 'Affiliation.csv' => affiliation_source,
  # 'Funder.csv' => funder_source,
  # 'Inventory.csv' => inventory_source,
  # 'Organization.csv' => organization_source,
  # 'ProjectCoC.csv' => project_coc_source,

  # Enrollment Related
  # 'Disabilities.csv' => disability_source,
  # 'EmploymentEducation.csv' => employment_education_source,
  # 'EnrollmentCoC.csv' => enrollment_coc_source,
  # 'Exit.csv' => exit_source,
  # 'HealthAndDV.csv' => health_and_dv_source,
  # 'IncomeBenefits.csv' => income_benefits_source,
  # 'Services.csv' => service_source,
  # 'CurrentLivingSituation.csv' => current_living_situation_source,
  # 'Assessment.csv' => assessment_source,
  # 'AssessmentQuestions.csv' => assessment_question_source,
  # 'AssessmentResults.csv' => assessment_result_source,
  # 'Event.csv' => event_source,

  #  Other
  # 'Export.csv' => export_source,
  # 'Client.csv' => client_source,
  # 'Enrollment.csv' => enrollment_source,
  # 'Project.csv' => project_source,
  # 'User.csv' => user_source,

  class ProjectRelatedHmisTwentyTwentyTests
    TESTS ||= [
      {
        list: :organizations,
        klass: HmisCsvTwentyTwentyTwo::Exporter::Organization,
        export_method: :export_organizations,
      },
      {
        list: :inventories,
        klass: HmisCsvTwentyTwentyTwo::Exporter::Inventory,
        export_method: :export_inventories,
      },
      {
        list: :affiliations,
        klass: HmisCsvTwentyTwentyTwo::Exporter::Affiliation,
        export_method: :export_affiliations,
      },
      {
        list: :project_cocs,
        klass: HmisCsvTwentyTwentyTwo::Exporter::ProjectCoc,
        export_method: :export_project_cocs,
      },
      {
        list: :funders,
        klass: HmisCsvTwentyTwentyTwo::Exporter::Funder,
        export_method: :export_funders,
      },
    ].freeze
  end

  def csv_file_path(klass)
    File.join(exporter.file_path, klass.hud_csv_file_name)
  end
end

RSpec.configure do |rspec|
  rspec.include_context '2022 project setup', include_shared: true
end
