###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'csv' # needed by FakeData

# == Hmis::CreateFakeEnrollmentsJob
#
# Tool to generate fake Enrollment data for local development and staging environments.
# It generates households of varying sizes. The default behavior is to generate open enrollments for existing clients.
#
# Records it generates:
# - Clients (optionally)
# - Enrollments (Household size varies from 1-4, except for NBN shelters which are set to 1)
# - Exits (optionally)
# - Disabilities (only for intake stage)
# - Bed Night Services (for NBN projects, 1-100 per Enrollment)
# - Intake and Exit Assessments
#
# Usage:
#   Hmis::CreateFakeEnrollmentsJob.perform_now(num_households: 10)
#   Hmis::CreateFakeEnrollmentsJob.perform_now(num_households: 10, generate_clients: true, exited: true, project_ids: [72])
module Hmis
  class CreateFakeEnrollmentsJob < BaseJob
    include Hmis::Concerns::HmisArelHelper
    include NotifierConfig
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    BATCH_SIZE = 5_000
    HOUSEHOLD_SIZE_RANGE = 1..4
    ENTRY_DATE_RANGE = 1..(365 * 3) # 1d-3y ago

    def perform(
      num_households:,
      generate_clients: false,
      exited: false,
      project_ids: nil,
      data_source_id: nil,
      export_id: 'FAKED'
    )
      raise "won't create fake enrollments in production" if Rails.env.production?

      setup_notifier('CreateFakeEnrollmentsJob')
      @data_source = if data_source_id
        ::GrdaWarehouse::DataSource.hmis.find(data_source_id)
      else
        ::GrdaWarehouse::DataSource.hmis.sole # 'sole' will raise if there are >1 HMIS data sources
      end

      @hud_user_id = Hmis::Hud::User.system_user(data_source_id: @data_source.id).user_id
      @faker = ::GrdaWarehouse::FakeData.new
      @export_id = export_id

      project_scope = if project_ids
        Hmis::Hud::Project.where(data_source: @data_source, id: project_ids)
      else
        Hmis::Hud::Project.where(data_source: @data_source)
      end

      # Generate and import data in batches
      remaining = num_households
      num_batches = (num_households / BATCH_SIZE) + 1
      num_batches.times do |i|
        n = i + 1 == num_batches ? remaining : BATCH_SIZE
        log("Generating #{n} #{exited ? 'exited' : 'active'} households across #{project_scope.size} projects, #{generate_clients ? 'for new clients' : 'for existing clients'} (batch #{i + 1}/#{num_batches})...")
        Hmis::Hud::Base.transaction do
          generate_and_import_enrollment_data(
            num_households: n,
            generate_clients: generate_clients,
            exited: exited,
            projects: project_scope,
          )
        end
        remaining -= n
      end

      # Queue job to generate Warehouse Client records (or attaches to existing warehouse clients if duplicate)
      Hmis::Hud::Client.warehouse_identify_duplicate_clients if generate_clients
      # Queue job to generate ServiceHistoryEnrollments
      Hmis::Hud::Enrollment.queue_service_history_processing!
    end

    def delete_faked_data!(export_id: 'FAKED')
      Hmis::Hud::Enrollment.where(ExportID: export_id).each(&:destroy!)
      Hmis::Hud::Client.where(ExportID: export_id).each(&:destroy!)
    end

    protected

    def generate_and_import_enrollment_data(num_households:, projects:, generate_clients: false, exited: false)
      num_clients = num_households * 2
      # Find or create pool of clients to generate enrollments for
      client_pool = if generate_clients
        clients_to_import = num_clients.times.map { build_fake_client }
        log('Generating Clients...')
        import_result = ar_import(Hmis::Hud::Client, clients_to_import)
        Hmis::Hud::Client.where(id: import_result.ids)
      else
        Hmis::Hud::Client.where(data_source: @data_source).sample(num_clients)
      end

      # Build and import enrollments
      enrollments_to_import = []
      num_households.times do
        project = projects.sample
        enrollments_to_import += build_fake_household_enrollments(
          client_pool: client_pool,
          project: project,
          hh_size: project.es_nbn? ? 1 : rand(HOUSEHOLD_SIZE_RANGE),
        )
      end
      log('Generating Enrollments...')
      enrollments_result = ar_import(Hmis::Hud::Enrollment, enrollments_to_import)
      enrollments = Hmis::Hud::Enrollment.where(id: enrollments_result.ids)

      # generate Disability records (because this is often a big table in prod)
      log('Generating Disabilities and Exits...')
      disabilities_to_import = []
      exits_to_import = []
      enrollments.each do |enrollment|
        disabilities_to_import << build_fake_disabilities(enrollment)
        exits_to_import << build_fake_exit(enrollment) if exited
      end
      ar_import(Hmis::Hud::Disability, disabilities_to_import.flatten)
      ar_import(Hmis::Hud::Exit, exits_to_import) if exited

      log('Generating Bed Night Services...')
      services_to_import = []
      nbn_projects = projects.where(project_type: 1).pluck(:id)
      enrollments.where(project_pk: nbn_projects).preload(:exit).each do |enrollment|
        services_to_import << build_fake_bed_nights(enrollment)
      end
      ar_import(Hmis::Hud::Service, services_to_import.flatten)

      # generate Intake and Exit Assessments for the new Enrollments
      log('Generating Intake/Exit Assessments...')
      Hmis::MigrateAssessmentsJob.perform_now(
        data_source_id: @data_source.id,
        enrollments: enrollments,
        project_ids: projects.pluck(:id),
        generate_empty_intakes: true,
      )

      links = enrollments.heads_of_households.sample(10).map do |enrollment|
        @data_source.hmis_url_for(enrollment)
      end
      log("Created #{enrollments_to_import.size} Enrollments")
      log("Samples: #{links.join('   ')}")
    end

    def build_fake_household_enrollments(client_pool:, project:, hh_size:)
      hh_id = nil
      client_pool.sample(hh_size).each_with_index.map do |client, idx|
        enrollment = build_fake_enrollment(
          client: client,
          project: project,
          is_hoh: idx == 0,
        )
        enrollment.HouseholdID = hh_id if hh_id
        hh_id ||= enrollment.HouseholdID
        enrollment
      end
    end

    def build_fake_client
      date_created = to_datetime(today - rand(1000)) # might be after enrollment date, but probably fine
      client = Hmis::Hud::Client.new(
        **hud_attributes,
        PersonalID: Hmis::Hud::Base.generate_uuid,
        FirstName: @faker.fetch(field_name: :FirstName, real_value: nil),
        LastName: @faker.fetch(field_name: :LastName, real_value: nil),
        SSN: ['123456789', 'XXXXX1234'].sample,
        DOB: Faker::Date.between(from: 60.years.ago, to: 18.years.ago),
        VeteranStatus: rand_boolean(10) ? 0 : 1,
        DateCreated: date_created,
        DateUpdated: date_created,
      )
      client.assign_attributes(random_gender_attributes)
      client.assign_attributes(random_race_attributes)
      client
    end

    def build_fake_enrollment(client:, project:, is_hoh:)
      entry_date = today - rand(ENTRY_DATE_RANGE)
      enrollment = Hmis::Hud::Enrollment.new(
        **hud_attributes,
        EnrollmentID: Hmis::Hud::Base.generate_uuid,
        PersonalID: client.PersonalID,
        ProjectID: project.ProjectID,
        project_pk: project.id,
        EntryDate: entry_date,
        RelationshipToHoH: is_hoh ? 1 : [4, 5].sample,
        HouseholdID: Hmis::Hud::Base.generate_uuid,
        DisablingCondition: rand_boolean ? 1 : 0,
        DateCreated: to_datetime(entry_date),
        DateUpdated: to_datetime(entry_date),
        LivingSituation: HudUtility2024.prior_living_situations.keys.sample,
      )
      # rubocop:disable Style/IfUnlessModifier
      if is_hoh && HudUtility2024.doe_project_types.include?(project.ProjectType) && rand_boolean(10)
        enrollment.DateOfEngagement = [enrollment.EntryDate + rand(30), today].min
      end
      if is_hoh && HudUtility2024.permanent_housing_project_types.include?(project.ProjectType) && rand_boolean(10)
        enrollment.MoveInDate = [enrollment.EntryDate + rand(30), today].min
      end
      # rubocop:enable Style/IfUnlessModifier

      enrollment
    end

    def build_fake_bed_nights(enrollment)
      bed_night_dates = rand(1..100).times.map do
        rand(enrollment.entry_date..(enrollment.exit_date || today))
      end
      bed_night_dates << enrollment.entry_date

      bed_night_dates.uniq.map do |dt|
        Hmis::Hud::Service.new(
          date_provided: dt,
          record_type: 200,
          type_provided: 200,
          enrollment_id: enrollment.enrollment_id,
          personal_id: enrollment.personal_id,
          date_created: to_datetime(dt),
          date_updated: to_datetime(dt),
          **hud_attributes,
        )
      end
    end

    def build_fake_exit(enrollment)
      exit_date = [enrollment.EntryDate + rand(30..1000), today].min
      Hmis::Hud::Exit.new(
        enrollment: enrollment,
        exit_date: exit_date,
        destination: HudUtility2024.destinations.keys.excluding(17).sample,
        DateCreated: to_datetime(exit_date),
        DateUpdated: to_datetime(exit_date),
        **hud_attributes,
      )
    end

    def build_fake_disabilities(enrollment)
      HudUtility2024.disability_types.keys.map.each do |type|
        # if enrollment's overall DisablingCondition is No, then none of the disabilities should be indefinite and impairing
        indefinite_and_impairs = enrollment.DisablingCondition == 0 ? 0 : [0, 1, 1].sample
        Hmis::Hud::Disability.new(
          enrollment: enrollment,
          DisabilityType: type,
          DisabilityResponse: [0, 1].sample,
          IndefiniteAndImpairs: [6, 8].include?(type) ? nil : indefinite_and_impairs,
          DataCollectionStage: 1, # intake
          InformationDate: enrollment.EntryDate,
          DateCreated: enrollment.DateCreated,
          DateUpdated: enrollment.DateUpdated,
          **hud_attributes,
        )
      end
    end

    def hud_attributes
      {
        data_source_id: @data_source.id,
        UserID: @hud_user_id,
        ExportID: @export_id,
      }
    end

    def ar_import(klass, records)
      result = klass.import(records, validate: true, timestamps: true)
      raise "failed to import #{klass.name}: #{result}" if result.failed_instances.any?

      log("Imported #{records.count} records of type #{klass.name}")
      result
    end

    # returns true 75% of the time. higher n = more likely to return true. 50/50 would be n=2
    def rand_boolean(num = 4)
      rand(num) != 1
    end

    def to_datetime(date)
      date.to_datetime + rand(8..20).hours # randomize time of day
    end

    # rubocop:disable Lint/EachWithObjectArgument
    def random_race_attributes
      race_attributes = HudUtility2024.races.keys.excluding('RaceNone').each_with_object(0).to_h
      race_attributes[race_attributes.keys.sample] = 1
      race_attributes[race_attributes.keys.sample] = 1 if rand_boolean # set another race
      race_attributes
    end

    def random_gender_attributes
      gender_attributes = HudUtility2024.gender_fields.map(&:to_s).excluding('GenderNone').each_with_object(0).to_h
      gender_attributes[gender_attributes.keys.sample] = 1
      gender_attributes[gender_attributes.keys.sample] = 1 if rand_boolean # set another gender
      gender_attributes
    end
    # rubocop:enable Lint/EachWithObjectArgument

    def log(message)
      @notifier&.ping("[FakeDataGenerator] #{message}")
    end

    def today
      @today ||= Date.current
    end
  end
end
