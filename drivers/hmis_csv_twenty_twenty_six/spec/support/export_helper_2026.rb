###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ExportHelper2026
  class << self
    attr_reader :data_source, :user, :projects, :organizations, :inventories,
                :affiliations, :project_cocs, :funders, :enrollments, :clients,
                :destination_data_source, :destination_clients, :exporter,
                :disabilities, :employment_educations, :health_and_dvs,
                :income_benefits, :services, :exits, :assessments,
                :assessment_questions, :assessment_results, :events,
                :current_living_situations, :ce_participations, :hmis_participations,
                :project_class, :project_coc_class, :enrollment_class,
                :client_class, :exit_class, :income_benefit_class

    def setup_data
      @data_source = FactoryBot.create :source_data_source
      @user = FactoryBot.create :user
      @projects = FactoryBot.create_list :hud_project, 5, data_source_id: @data_source.id
      @projects.first.update(ProjectType: 3, ExportID: 1) # ensure the first project is PH
      @organizations = FactoryBot.create_list :hud_organization, 5, data_source_id: @data_source.id
      @inventories = FactoryBot.create_list :hud_inventory, 5, data_source_id: @data_source.id
      @affiliations = FactoryBot.create_list :hud_affiliation, 5, data_source_id: @data_source.id
      @project_cocs = FactoryBot.create_list :hud_project_coc, 5, data_source_id: @data_source.id, CoCCode: 'XX-500'
      @funders = FactoryBot.create_list :hud_funder, 5, data_source_id: @data_source.id

      @enrollments = FactoryBot.create_list :hud_enrollment, 5, data_source_id: @data_source.id, EntryDate: 2.weeks.ago, PreferredLanguageDifferent: 'a' * 200, EnrollmentCoC: 'XX-500'
      @enrollments.first.update(MoveInDate: 1.week.ago)

      @clients = FactoryBot.create_list(
        :hud_client,
        5,
        data_source_id: @data_source.id,
        FirstName: 'abcde' * 12,
        LastName: 'xyz' * 50,
        MiddleName: 'M',
        SSN: Faker::Number.number(digits: 9),
      )

      @destination_data_source = FactoryBot.create :grda_warehouse_data_source

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

      @disabilities = FactoryBot.create_list :hud_disability, 5, data_source_id: @data_source.id, InformationDate: 1.week.ago
      @employment_educations = FactoryBot.create_list :hud_employment_education, 5, data_source_id: @data_source.id, InformationDate: 1.week.ago
      @health_and_dvs = FactoryBot.create_list :hud_health_and_dv, 5, data_source_id: @data_source.id, InformationDate: 1.week.ago
      @income_benefits = FactoryBot.create_list :hud_income_benefit, 5, data_source_id: @data_source.id, InformationDate: 1.week.ago
      @services = FactoryBot.create_list :hud_service, 5, data_source_id: @data_source.id, DateProvided: 1.week.ago
      @exits = FactoryBot.create_list :hud_exit, 5, data_source_id: @data_source.id, ExitDate: Date.yesterday
      @assessments = FactoryBot.create_list :hud_assessment, 5, data_source_id: @data_source.id, AssessmentDate: Date.yesterday
      @assessment_questions = FactoryBot.create_list :hud_assessment_question, 5, data_source_id: @data_source.id
      @assessment_results = FactoryBot.create_list :hud_assessment_result, 5, data_source_id: @data_source.id
      @events = FactoryBot.create_list :hud_event, 5, data_source_id: @data_source.id
      @current_living_situations = FactoryBot.create_list :hud_current_living_situation, 5, data_source_id: @data_source.id
      @ce_participations = FactoryBot.create_list :hud_ce_participation, 5, data_source_id: @data_source.id
      @hmis_participations = FactoryBot.create_list :hud_hmis_participation, 5, data_source_id: @data_source.id

      @project_class = HmisCsvTwentyTwentySix::Exporter::Project
      @project_coc_class = HmisCsvTwentyTwentySix::Exporter::ProjectCoc
      @enrollment_class = HmisCsvTwentyTwentySix::Exporter::Enrollment
      @client_class = HmisCsvTwentyTwentySix::Exporter::Client
      @exit_class = HmisCsvTwentyTwentySix::Exporter::Exit
      @income_benefit_class = HmisCsvTwentyTwentySix::Exporter::IncomeBenefit
    end

    def cleanup
      @exporter&.remove_export_files
      cleanup_test_environment
    end

    def csv_file_path(klass, exporter: @exporter)
      return File.join(exporter.file_path, 'Export.csv') if klass == HmisCsvTwentyTwentySix::Exporter::Export

      return File.join(exporter.file_path, exporter.hmis_class_for(klass).hud_csv_file_name(version: '2026')) unless klass.is_a?(String)

      # If klass is a string like 'CEParticipation', convert it to the corresponding exporter class
      klass = "HmisCsvTwentyTwentySix::Exporter::#{normalize_class_name(klass)}".constantize
      File.join(exporter.file_path, exporter.file_name_for(klass))
    end

    def normalize_class_name(klass)
      case klass
      when 'CEParticipation'
        'CeParticipation'
      when 'HMISParticipation'
        'HmisParticipation'
      when 'Services'
        'Service'
      else
        klass
      end
    end

    def project_classes
      project_related_items.values
    end

    def project_related_items
      {
        organizations: HmisCsvTwentyTwentySix::Exporter::Organization,
        inventories: HmisCsvTwentyTwentySix::Exporter::Inventory,
        affiliations: HmisCsvTwentyTwentySix::Exporter::Affiliation,
        project_cocs: HmisCsvTwentyTwentySix::Exporter::ProjectCoc,
        funders: HmisCsvTwentyTwentySix::Exporter::Funder,
      }
    end

    def enrollment_classes
      enrollment_related_items.values
    end

    def enrollment_related_items
      {
        disabilities: HmisCsvTwentyTwentySix::Exporter::Disability,
        employment_educations: HmisCsvTwentyTwentySix::Exporter::EmploymentEducation,
        health_and_dvs: HmisCsvTwentyTwentySix::Exporter::HealthAndDv,
        income_benefits: HmisCsvTwentyTwentySix::Exporter::IncomeBenefit,
        services: HmisCsvTwentyTwentySix::Exporter::Service,
        exits: HmisCsvTwentyTwentySix::Exporter::Exit,
        assessments: HmisCsvTwentyTwentySix::Exporter::Assessment,
        assessment_questions: HmisCsvTwentyTwentySix::Exporter::AssessmentQuestion,
        assessment_results: HmisCsvTwentyTwentySix::Exporter::AssessmentResult,
        events: HmisCsvTwentyTwentySix::Exporter::Event,
        current_living_situations: HmisCsvTwentyTwentySix::Exporter::CurrentLivingSituation,
      }
    end
  end
end
