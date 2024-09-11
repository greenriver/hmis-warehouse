require 'csv' # needed by FakeData

# Tool to generate fake Enrollment data for local development and staging environments.
# It generates households of varying sizes.
# The default behavior is to generate open enrollments for existing clients.
#
# Records it generates:
# - Clients (optionally)
# - Enrollments
# - Exits (optionally)
# - Disabilities
# - Bed Night Services (for NBN projects)
# - Intake and Exit Assessments
#
# Usage:
#
# HmisUtil::FakeDataGenerator.new.generate_enrollments!
# HmisUtil::FakeDataGenerator.new.generate_enrollments!(generate_clients: true, num_households: 3)
# HmisUtil::FakeDataGenerator.new.generate_enrollments!(exited: true)
# HmisUtil::FakeDataGenerator.new.generate_enrollments!(project_types: [1]) # NBN only, which will generate bed nights
class HmisUtil::FakeDataGenerator
  def initialize(export_id: 'FAKED', data_source_id: nil)
    raise "can't run fake data generator in production" if Rails.env.production?

    @data_source = if data_source_id
      GrdaWarehouse::DataSource.hmis.find(data_source_id)
    else
      GrdaWarehouse::DataSource.hmis.sole # 'sole' will raise if there are >1 HMIS data sources
    end

    @hud_user_id = Hmis::Hud::User.system_user(data_source_id: @data_source.id).user_id
    @faker = GrdaWarehouse::FakeData.new
    @export_id = export_id
  end

  def generate_enrollments!(num_households: 10, generate_clients: false, exited: false, project_types: nil)
    project_scope = Hmis::Hud::Project.where(data_source: @data_source)
    project_scope = project_scope.where(project_type: project_types) if project_types
    # choose 50 random projects to generate enrollments for
    projects = Hmis::Hud::Project.where(id: project_scope.ids.sample(50))
    num_clients = num_households * 4

    Hmis::Hud::Base.transaction do
      # Find or create pool of clients to generate enrollments for
      client_pool = if generate_clients
        clients_to_import = num_clients.times.map { build_fake_client }
        Rails.logger.info('Generating Clients...')
        import_result = perform_import(Hmis::Hud::Client, clients_to_import)
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
          hh_size: project.es_nbn? ? 1 : rand(1..4),
        )
      end
      Rails.logger.info('Generating Enrollments...')
      enrollments_result = perform_import(Hmis::Hud::Enrollment, enrollments_to_import)

      # generate Disability records (because this is often a big table in prod)
      Rails.logger.info('Generating Disabilities and Exits...')
      disabilities_to_import = []
      exits_to_import = []
      Hmis::Hud::Enrollment.where(id: enrollments_result.ids).each do |enrollment|
        disabilities_to_import << build_fake_disabilities(enrollment)
        exits_to_import << build_fake_exit(enrollment) if exited
      end
      perform_import(Hmis::Hud::Disability, disabilities_to_import.flatten)
      perform_import(Hmis::Hud::Exit, exits_to_import) if exited

      Rails.logger.info('Generating Bed Night Services...')
      services_to_import = []
      nbn_projects = projects.where(project_type: 1).pluck(:id)
      Hmis::Hud::Enrollment.where(id: enrollments_result.ids, project_pk: nbn_projects).each do |enrollment|
        services_to_import << build_fake_bed_nights(enrollment)
      end
      perform_import(Hmis::Hud::Service, services_to_import.flatten)

      # generate Intake and Exit Assessments (note: this will affect other enrollments too)
      Rails.logger.info('Generating Intake/Exit Assessments...')
      Hmis::MigrateAssessmentsJob.perform_now(
        data_source_id: @data_source.id,
        project_ids: projects.pluck(:id),
        generate_empty_intakes: true,
      )

      links = Hmis::Hud::Enrollment.where(id: enrollments_result.ids.take(50)).heads_of_households.map do |enrollment|
        @data_source.hmis_url_for(enrollment)
      end
      Rails.logger.info "Created #{enrollments_to_import.size} Enrollments"
      Rails.logger.info("Samples:\n#{links.join("\n")}")
    end
  end

  def delete_faked_data!(export_id: 'FAKED')
    Hmis::Hud::Enrollment.where(ExportID: export_id).each(&:destroy!)
    Hmis::Hud::Client.where(ExportID: export_id).each(&:destroy!)
  end

  protected

  def perform_import(klass, records)
    result = klass.import(records, validate: true, timestamps: true)
    raise "failed to import #{klass.name}: #{result}" if result.failed_instances.any?

    Rails.logger.info("Imported #{records.count} records of type #{klass.name}")
    result
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
    end.flatten
  end

  def build_fake_client
    date_created = to_datetime_6pm(Date.current - rand(1000)) # might be after enrollment date, but probably fine
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
    entry_date = Date.current - rand(1000)
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
      DateCreated: to_datetime_6pm(entry_date),
      DateUpdated: to_datetime_6pm(entry_date),
      LivingSituation: HudUtility2024.prior_living_situations.keys.sample,
    )
    # rubocop:disable Style/IfUnlessModifier
    if is_hoh && HudUtility2024.doe_project_types.include?(project.ProjectType) && rand_boolean(10)
      enrollment.DateOfEngagement = [enrollment.EntryDate + rand(30), Date.current].min
    end
    if is_hoh && HudUtility2024.permanent_housing_project_types.include?(project.ProjectType) && rand_boolean(10)
      enrollment.MoveInDate = [enrollment.EntryDate + rand(30), Date.current].min
    end
    # rubocop:enable Style/IfUnlessModifier

    enrollment
  end

  def build_fake_bed_nights(enrollment, max_count = 100)
    bed_night_dates = max_count.times.map { rand(enrollment.entry_date..enrollment.exit_date) }
    bed_night_dates << enrollment.entry_date

    bed_night_dates.uniq.map do |dt|
      Hmis::Hud::Service.new(
        date_provided: dt,
        record_type: 200,
        type_provided: 200,
        enrollment_id: enrollment.enrollment_id,
        personal_id: enrollment.personal_id,
        date_created: to_datetime_6pm(dt),
        date_updated: to_datetime_6pm(dt),
        **hud_attributes,
      )
    end
  end

  def build_fake_exit(enrollment)
    exit_date = [enrollment.EntryDate + rand(30..1000), Date.current].min
    Hmis::Hud::Exit.new(
      enrollment: enrollment,
      exit_date: exit_date,
      destination: HudUtility2024.destinations.keys.excluding(17).sample,
      DateCreated: to_datetime_6pm(exit_date),
      DateUpdated: to_datetime_6pm(exit_date),
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

  # returns true 75% of the time. higher n = more likely to return true. 50/50 would be n=2
  def rand_boolean(num = 4)
    rand(num) != 1
  end

  def to_datetime_6pm(date)
    date.to_datetime + 18.hours
  end

  # rubocop:disable Lint/EachWithObjectArgument
  def random_race_attributes
    race_attributes = HudUtility2024.races.keys.excluding('RaceNone').each_with_object(0).to_h
    race_attributes[race_attributes.keys.sample] = 1
    race_attributes[race_attributes.keys.sample] = 1 if rand_boolean # set another race
    race_attributes['RaceNone'] = 99
    race_attributes
  end

  def random_gender_attributes
    gender_attributes = HudUtility2024.gender_fields.map(&:to_s).excluding('GenderNone').each_with_object(0).to_h
    gender_attributes[gender_attributes.keys.sample] = 1
    gender_attributes[gender_attributes.keys.sample] = 1 if rand_boolean # set another gender
    gender_attributes['GenderNone'] = 99
    gender_attributes
  end
  # rubocop:enable Lint/EachWithObjectArgument
end
