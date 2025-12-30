# frozen_string_literal: true

require 'rails_helper'
require_relative './hud_enrollment_builders'

# Shared context for HUD report performance testing utilities
# Provides bulk building methods optimized for creating large test datasets
RSpec.shared_context 'HUD report performance helpers', shared_context: :metadata do
  include_context 'HUD enrollment builders'

  let(:household_sequence) do
    Enumerator.new do |y|
      i = 0
      loop { y << "HH-#{SecureRandom.uuid}-#{i += 1}" }
    end
  end

  def build_household(projects:, entry_date:, exit_date:, members: 1, destination: nil, living_situation: 100, date_to_street_essh: nil, include_move_in: false, move_in_offset: 0, data_source_override: nil, household_id: nil) # rubocop:disable Metrics/ParameterLists
    household_id ||= household_sequence.next
    members.times.flat_map do |index|
      client = create_client_with_warehouse_link
      relationship = index.zero? ? 1 : 2
      projects.map do |project|
        move_in_date = nil
        move_in_date = entry_date + move_in_offset if include_move_in && relationship == 1
        create_enrollment(
          client: client,
          project: project,
          entry_date: entry_date,
          exit_date: exit_date,
          relationship_to_ho_h: relationship,
          date_to_street_essh: date_to_street_essh,
          household_id: household_id,
          living_situation: living_situation,
          destination: destination,
          move_in_date: move_in_date,
        ).tap do |enrollment|
          enrollment.update!(data_source: data_source_override) if data_source_override
          yield client, enrollment if block_given?
        end
      end
    end
  end

  def add_income_snapshot(enrollment:, information_date:, data_collection_stage:, earned_amount:, other_income_amount:)
    total_income = earned_amount.to_f + other_income_amount.to_f
    create(
      :hud_income_benefit,
      enrollment: enrollment,
      data_source: enrollment.data_source,
      information_date: information_date,
      data_collection_stage: data_collection_stage,
      earned_amount: earned_amount,
      total_monthly_income: total_income,
      other_income_amount: other_income_amount,
    )
  end

  def add_bed_nights(enrollment:, start_date:, end_date:)
    (start_date...end_date).each do |date|
      create_bed_night_service(enrollment: enrollment, date: date)
    end
  end

  def build_return_scenario(project:, entry_date:, exit_date:, destination:, return_entry_date:, return_exit_date:)
    client = create_client_with_warehouse_link
    enrollment = create_enrollment(
      client: client,
      project: project,
      entry_date: entry_date,
      exit_date: exit_date,
      relationship_to_ho_h: 1,
      destination: destination,
      living_situation: 1,
    )
    return_enrollment = create_enrollment(
      client: client,
      project: project,
      entry_date: return_entry_date,
      exit_date: return_exit_date,
      relationship_to_ho_h: 1,
      living_situation: 1,
    )
    [client, enrollment, return_enrollment]
  end

  def bulk_build_standard_enrollments(source_clients:, projects:, project_coc_codes:, base_entry_date:, household_count:, members_per_household:, enrollments_per_member:, enrollments:, exits:, include_move_in: false)
    household_count.times do |household_index|
      household_id = SecureRandom.uuid
      members_per_household.times do |member_index|
        client_index = (household_index * members_per_household) + member_index
        client = source_clients[client_index]
        relationship = member_index.zero? ? 1 : 2

        enrollments_per_member.times do |enrollment_index|
          project = projects[(household_index + enrollment_index) % projects.length]
          project_index = projects.index(project)
          entry_date = base_entry_date + enrollment_index.days
          exit_date = entry_date + 1.day

          enrollment = build(
            :hud_enrollment,
            client: client,
            project: project,
            data_source: data_source,
            entry_date: entry_date,
            date_to_street_essh: entry_date - 30.days,
            relationship_to_ho_h: relationship,
            household_id: household_id,
            living_situation: 100,
            move_in_date: include_move_in && relationship == 1 ? entry_date : nil,
            enrollment_coc: project_coc_codes[project_index],
          )
          enrollments << enrollment

          exit_record = build(
            :hud_exit,
            personal_id: client.personal_id,
            data_source_id: data_source.id,
            exit_date: exit_date,
            destination: 30,
          )
          exits << exit_record
        end
      end
    end
  end

  def bulk_build_measure_two_enrollments(source_clients:, projects:, project_coc_codes:, base_entry_date:, household_count:, members_per_household:, enrollments_per_member:, enrollments:, exits:, include_move_in: false)
    # For Measure Two: exits need to be 2 years before report period
    # Report period is typically base_entry_date to base_entry_date + 1.year
    # So exits should be around base_entry_date - 730.days (2 years before)
    exit_base_date = base_entry_date - 730.days

    household_count.times do |household_index|
      household_id = SecureRandom.uuid
      members_per_household.times do |member_index|
        client_index = (household_index * members_per_household) + member_index
        client = source_clients[client_index]
        relationship = member_index.zero? ? 1 : 2

        enrollments_per_member.times do |enrollment_index|
          project = projects[(household_index + enrollment_index) % projects.length]
          project_index = projects.index(project)

          # First enrollment: exit to permanent housing 2 years before report period
          entry_date = exit_base_date - 30.days + enrollment_index.days
          exit_date = exit_base_date + enrollment_index.days

          enrollment = build(
            :hud_enrollment,
            client: client,
            project: project,
            data_source: data_source,
            entry_date: entry_date,
            date_to_street_essh: entry_date - 30.days,
            relationship_to_ho_h: relationship,
            household_id: household_id,
            living_situation: 100,
            move_in_date: include_move_in && relationship == 1 ? entry_date : nil,
            enrollment_coc: project_coc_codes[project_index],
          )
          enrollments << enrollment

          # Exit to permanent housing (410 = Rental by client, no ongoing housing subsidy)
          exit_record = build(
            :hud_exit,
            personal_id: client.personal_id,
            data_source_id: data_source.id,
            exit_date: exit_date,
            destination: 410,
          )
          exits << exit_record

          # Second enrollment: return to homelessness in different time windows
          # Stagger returns across 0-180, 181-365, 366-730 day windows
          days_to_return = case enrollment_index % 3
          when 0 then 90   # 0-180 days
          when 1 then 270  # 181-365 days
          else 500         # 366-730 days
          end

          return_entry_date = exit_date + days_to_return.days
          return_exit_date = return_entry_date + 7.days

          return_enrollment = build(
            :hud_enrollment,
            client: client,
            project: project,
            data_source: data_source,
            entry_date: return_entry_date,
            date_to_street_essh: return_entry_date - 30.days,
            relationship_to_ho_h: relationship,
            household_id: SecureRandom.uuid, # Different household for return
            living_situation: 116, # Place not meant for habitation
            enrollment_coc: project_coc_codes[project_index],
          )
          enrollments << return_enrollment

          return_exit_record = build(
            :hud_exit,
            personal_id: client.personal_id,
            data_source_id: data_source.id,
            exit_date: return_exit_date,
            destination: 30, # No exit interview completed
          )
          exits << return_exit_record
        end
      end
    end
  end

  # Optimized bulk insert for performance testing
  # Instead of individual creates (O(n) database calls), this method:
  # 1. Builds all records in memory
  # 2. Bulk imports clients (source + destination)
  # 3. Bulk imports warehouse_client links
  # 4. Bulk imports enrollments and exits
  # 5. Optionally bulk creates bed nights for ES Night-by-Night enrollments
  # 6. Optionally bulk creates CoC funders for projects
  # 7. Optionally bulk creates income benefits for enrollments
  # This reduces database round trips from thousands to a handful
  def bulk_build_households(projects:, base_entry_date:, household_count:, members_per_household:, enrollments_per_member:, create_bed_nights: false, measure_two_pattern: false, create_coc_funders: false, create_income_benefits: false, include_move_in: false)
    total_clients = household_count * members_per_household

    # Build all client records in memory first
    source_clients = []
    destination_clients = []

    total_clients.times do
      personal_id = SecureRandom.uuid.gsub(/-/, '')

      source_client = build(
        :hud_client,
        personal_id: personal_id,
        data_source: data_source,
        dob: '1995-04-05'.to_date,
        name_data_quality: 1,
        dob_data_quality: 1,
      )

      destination_client = source_client.dup
      destination_client.data_source = destination_data_source
      destination_client.apply_housing_release_status if destination_client.respond_to?(:apply_housing_release_status)

      source_clients << source_client
      destination_clients << destination_client
    end

    # Bulk import source clients
    GrdaWarehouse::Hud::Client.import(source_clients, validate: false)
    source_clients.each(&:reload)

    # Bulk import destination clients
    GrdaWarehouse::Hud::Client.import(destination_clients, validate: false)
    destination_clients.each(&:reload)

    # Create warehouse_client links
    warehouse_clients_records = source_clients.each_with_index.map do |source_client, index|
      build(
        :warehouse_client,
        source_id: source_client.id,
        destination_id: destination_clients[index].id,
      )
    end
    GrdaWarehouse::WarehouseClient.import(warehouse_clients_records, validate: false)

    # Get project CoC codes once
    project_coc_codes = projects.map { |p| p.project_cocs.min_by(&:id).coc_code }

    # Bulk create CoC funders if requested
    bulk_create_coc_funders(projects: projects, start_date: base_entry_date) if create_coc_funders

    # Build all enrollment and exit records in memory
    enrollments = []
    exits = []

    if measure_two_pattern
      bulk_build_measure_two_enrollments(
        source_clients: source_clients,
        projects: projects,
        project_coc_codes: project_coc_codes,
        base_entry_date: base_entry_date,
        household_count: household_count,
        members_per_household: members_per_household,
        enrollments_per_member: enrollments_per_member,
        enrollments: enrollments,
        exits: exits,
        include_move_in: include_move_in,
      )
    else
      bulk_build_standard_enrollments(
        source_clients: source_clients,
        projects: projects,
        project_coc_codes: project_coc_codes,
        base_entry_date: base_entry_date,
        household_count: household_count,
        members_per_household: members_per_household,
        enrollments_per_member: enrollments_per_member,
        enrollments: enrollments,
        exits: exits,
        include_move_in: include_move_in,
      )
    end

    # Bulk import enrollments
    GrdaWarehouse::Hud::Enrollment.import(enrollments, validate: false)
    enrollments.each(&:reload)

    # Update exits with enrollment IDs and bulk import
    exits.each_with_index do |exit_record, index|
      exit_record.enrollment_id = enrollments[index].id
    end
    GrdaWarehouse::Hud::Exit.import(exits, validate: false)

    # Bulk create bed nights for ES Night-by-Night enrollments
    if create_bed_nights
      bed_nights = []
      # Preload projects and exits to avoid N+1 queries
      GrdaWarehouse::Hud::Enrollment.where(id: enrollments.map(&:id)).preload(:project, :exit).find_each do |enrollment|
        next unless enrollment.project.project_type == 1
        next unless enrollment.exit&.exit_date

        (enrollment.entry_date...enrollment.exit.exit_date).each do |date|
          bed_nights << build(
            :hud_service,
            enrollment: enrollment,
            personal_id: enrollment.personal_id,
            data_source: enrollment.data_source,
            record_type: 200,
            date_provided: date,
          )
        end
      end

      GrdaWarehouse::Hud::Service.import(bed_nights, validate: false) if bed_nights.any?
    end

    # Bulk create income benefits
    bulk_create_income_benefits(enrollments: enrollments) if create_income_benefits
  end

  def bulk_create_coc_funders(projects:, start_date:)
    funders = projects.map do |project|
      build(
        :hud_funder,
        project: project,
        data_source: project.data_source,
        Funder: HudHelper.util('2026').spm_coc_funders.first,
        StartDate: start_date - 3.years,
        EndDate: nil,
      )
    end
    GrdaWarehouse::Hud::Funder.import(funders, validate: false)
  end

  def bulk_create_income_benefits(enrollments:)
    income_benefits = []

    GrdaWarehouse::Hud::Enrollment.where(id: enrollments.map(&:id)).preload(:exit).find_each do |enrollment|
      # Entry income (stage 1)
      income_benefits << build(
        :hud_income_benefit,
        enrollment: enrollment,
        personal_id: enrollment.personal_id,
        data_source: enrollment.data_source,
        data_collection_stage: 1,
        information_date: enrollment.entry_date,
        earned_amount: 500,
        other_income_amount: 100,
        total_monthly_income: 600,
      )

      # Annual assessment or exit income (stage 5 or 3)
      # Create annual assessment if enrolled long enough, otherwise exit income
      next unless enrollment.exit&.exit_date

      assessment_date = enrollment.entry_date + 365.days
      if enrollment.exit.exit_date >= assessment_date
        # Annual assessment (stage 5)
        income_benefits << build(
          :hud_income_benefit,
          enrollment: enrollment,
          personal_id: enrollment.personal_id,
          data_source: enrollment.data_source,
          data_collection_stage: 5,
          information_date: assessment_date,
          earned_amount: 700,
          other_income_amount: 200,
          total_monthly_income: 900,
        )
      else
        # Exit income (stage 3) - increased income for variety
        income_benefits << build(
          :hud_income_benefit,
          enrollment: enrollment,
          personal_id: enrollment.personal_id,
          data_source: enrollment.data_source,
          data_collection_stage: 3,
          information_date: enrollment.exit.exit_date,
          earned_amount: 650,
          other_income_amount: 150,
          total_monthly_income: 800,
        )
      end
    end

    GrdaWarehouse::Hud::IncomeBenefit.import(income_benefits, validate: false) if income_benefits.any?
  end
end
