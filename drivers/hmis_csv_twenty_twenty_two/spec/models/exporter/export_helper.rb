def csv_file_path(klass, exporter: @exporter)
  File.join(exporter.file_path, exporter.file_name_for(klass))
end

def cleanup_test_environment
  HmisCsvImporter::Utility.clear!
  GrdaWarehouse::Utility.clear!
  User.delete_all
  FactoryBot.reload
end

def setup_data
  @data_source = create :source_data_source
  @user = create :user
  @projects = create_list :hud_project, 5, data_source_id: @data_source.id
  @organizations = create_list :hud_organization, 5, data_source_id: @data_source.id
  @inventories = create_list :hud_inventory, 5, data_source_id: @data_source.id
  @affiliations = create_list :hud_affiliation, 5, data_source_id: @data_source.id
  @project_cocs = create_list :hud_project_coc, 5, data_source_id: @data_source.id
  @funders = create_list :hud_funder, 5, data_source_id: @data_source.id

  @enrollments = create_list :hud_enrollment, 5, data_source_id: @data_source.id, EntryDate: 2.weeks.ago
  @clients = create_list :hud_client, 5, data_source_id: @data_source.id
  @destination_data_source = create :grda_warehouse_data_source

  @destination_clients = @clients.map do |client|
    attributes = client.attributes
    attributes['data_source_id'] = @destination_data_source.id
    attributes['id'] = nil
    dest_client = GrdaWarehouse::Hud::Client.create(attributes)
    GrdaWarehouse::WarehouseClient.create(
      id_in_source: client.PersonalID,
      data_source_id: client.data_source_id,
      source_id: client.id,
      destination_id: dest_client.id,
    )
  end

  @disabilities = create_list :hud_disability, 5, data_source_id: @data_source.id, InformationDate: 1.week.ago
  @enrollment_cocs = create_list :hud_enrollment_coc, 5, data_source_id: @data_source.id, InformationDate: 1.week.ago
  @employment_educations = create_list :hud_employment_education, 5, data_source_id: @data_source.id, InformationDate: 1.week.ago
  @health_and_dvs = create_list :hud_health_and_dv, 5, data_source_id: @data_source.id, InformationDate: 1.week.ago
  @income_benefits = create_list :hud_income_benefit, 5, data_source_id: @data_source.id, InformationDate: 1.week.ago
  @services = create_list :hud_service, 5, data_source_id: @data_source.id, DateProvided: 1.week.ago
  @exits = create_list :hud_exit, 5, data_source_id: @data_source.id, ExitDate: Date.yesterday
  @assessments = create_list :hud_assessment, 5, data_source_id: @data_source.id, AssessmentDate: Date.yesterday
  @assessment_questions = create_list :hud_assessment_question, 5, data_source_id: @data_source.id
  @assessment_results = create_list :hud_assessment_result, 5, data_source_id: @data_source.id
  @events = create_list :hud_event, 5, data_source_id: @data_source.id
  @current_living_situations = create_list :hud_current_living_situation, 5, data_source_id: @data_source.id
end

def project_classes
  [
    HmisCsvTwentyTwentyTwo::Exporter::Organization,
    HmisCsvTwentyTwentyTwo::Exporter::Inventory,
    HmisCsvTwentyTwentyTwo::Exporter::Affiliation,
    HmisCsvTwentyTwentyTwo::Exporter::ProjectCoc,
    HmisCsvTwentyTwentyTwo::Exporter::Funder,
  ]
end

def enrollment_classes
  [
    HmisCsvTwentyTwentyTwo::Exporter::Disability,
    HmisCsvTwentyTwentyTwo::Exporter::EnrollmentCoc,
    HmisCsvTwentyTwentyTwo::Exporter::EmploymentEducation,
    HmisCsvTwentyTwentyTwo::Exporter::HealthAndDv,
    HmisCsvTwentyTwentyTwo::Exporter::IncomeBenefit,
    HmisCsvTwentyTwentyTwo::Exporter::Service,
    HmisCsvTwentyTwentyTwo::Exporter::Exit,
    HmisCsvTwentyTwentyTwo::Exporter::Assessment,
    HmisCsvTwentyTwentyTwo::Exporter::AssessmentQuestion,
    HmisCsvTwentyTwentyTwo::Exporter::AssessmentResult,
    HmisCsvTwentyTwentyTwo::Exporter::Event,
    HmisCsvTwentyTwentyTwo::Exporter::CurrentLivingSituation,
  ]
end
