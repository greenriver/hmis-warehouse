###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

def csv_file_path(klass, exporter: @exporter)
  File.join(exporter.file_path, exporter.file_name_for(klass))
end

def setup_data
  @data_source = create :source_data_source
  @user = create :user
  @projects = create_list :hud_project, 5, data_source_id: @data_source.id
  @projects.first.update(ProjectType: 3, ExportID: 1) # ensure the first project is PH
  @organizations = create_list :hud_organization, 5, data_source_id: @data_source.id
  @inventories = create_list :hud_inventory, 5, data_source_id: @data_source.id
  @affiliations = create_list :hud_affiliation, 5, data_source_id: @data_source.id
  @project_cocs = create_list :hud_project_coc, 5, data_source_id: @data_source.id, CoCCode: 'XX-500'
  @funders = create_list :hud_funder, 5, data_source_id: @data_source.id

  @enrollments = create_list :hud_enrollment, 5, data_source_id: @data_source.id, EntryDate: 2.weeks.ago, PreferredLanguageDifferent: 'a' * 200, EnrollmentCoC: 'XX-500'

  @clients = create_list(
    :hud_client,
    5,
    data_source_id: @data_source.id,
    FirstName: 'abcde' * 12,
    LastName: 'xyz' * 50,
    MiddleName: 'M',
    SSN: Faker::Number.number(digits: 9),
  )
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
  @ce_participations = create_list :hud_ce_participation, 5, data_source_id: @data_source.id
  @hmis_participations = create_list :hud_hmis_participation, 5, data_source_id: @data_source.id

  @project_class = HmisCsvTwentyTwentyFour::Exporter::Project
  @project_coc_class = HmisCsvTwentyTwentyFour::Exporter::ProjectCoc
  @enrollment_class = HmisCsvTwentyTwentyFour::Exporter::Enrollment
  @client_class = HmisCsvTwentyTwentyFour::Exporter::Client
  @exit_class = HmisCsvTwentyTwentyFour::Exporter::Exit
  @income_benefit_class = HmisCsvTwentyTwentyFour::Exporter::IncomeBenefit

  # Create a loader record for the project that isn't PH to test project_type_overridden_as_ph?
  project = @projects.first
  columns = project.class.hmis_structure(version: '2024').keys.map(&:to_s)
  attributes = project.attributes.slice(*columns)
  attributes.merge!(
    'ProjectType' => '1',
    'data_source_id' => project.data_source_id,
    'loaded_at' => DateTime.current - 1.days,
    'loader_id' => 1,
  )
  HmisCsvTwentyTwentyFour::Loader::Project.create(attributes)
end

def project_classes
  project_related_items.values
end

def project_related_items
  {
    organizations: HmisCsvTwentyTwentyFour::Exporter::Organization,
    inventories: HmisCsvTwentyTwentyFour::Exporter::Inventory,
    affiliations: HmisCsvTwentyTwentyFour::Exporter::Affiliation,
    project_cocs: HmisCsvTwentyTwentyFour::Exporter::ProjectCoc,
    funders: HmisCsvTwentyTwentyFour::Exporter::Funder,
  }
end

def enrollment_classes
  enrollment_related_items.values
end

def enrollment_related_items
  {
    disabilities: HmisCsvTwentyTwentyFour::Exporter::Disability,
    employment_educations: HmisCsvTwentyTwentyFour::Exporter::EmploymentEducation,
    health_and_dvs: HmisCsvTwentyTwentyFour::Exporter::HealthAndDv,
    income_benefits: HmisCsvTwentyTwentyFour::Exporter::IncomeBenefit,
    services: HmisCsvTwentyTwentyFour::Exporter::Service,
    exits: HmisCsvTwentyTwentyFour::Exporter::Exit,
    assessments: HmisCsvTwentyTwentyFour::Exporter::Assessment,
    assessment_questions: HmisCsvTwentyTwentyFour::Exporter::AssessmentQuestion,
    assessment_results: HmisCsvTwentyTwentyFour::Exporter::AssessmentResult,
    events: HmisCsvTwentyTwentyFour::Exporter::Event,
    current_living_situations: HmisCsvTwentyTwentyFour::Exporter::CurrentLivingSituation,
  }
end
