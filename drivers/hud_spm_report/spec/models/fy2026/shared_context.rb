###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../spec/shared_contexts/hud_enrollment_builders'

# Shared context for SPM testing
RSpec.shared_context 'SPM test setup', shared_context: :metadata do
  include_context 'HUD enrollment builders'
  let(:household_sequence) do
    Enumerator.new do |y|
      i = 0
      loop { y << "HH-#{SecureRandom.uuid}-#{i += 1}" }
    end
  end

  let(:default_filter) do
    Filters::HudFilterBase.new(
      user: user,
      start: '2022-10-01'.to_date,
      end: '2023-09-30'.to_date,
      coc_codes: ['MA-500'],
      enforce_one_year_range: false,
    )
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

  def setup_report(project_ids, questions = ['Measure 1'])
    filter = default_filter.dup
    filter.update(project_ids: project_ids)

    report = HudReports::ReportInstance.from_filter(
      filter,
      'System Performance Measures - FY 2026',
      build_for_questions: questions,
    )
    report.question_names = questions
    report.save!

    # Build ServiceHistoryEnrollments
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

    # Generate the SpmEnrollment records
    HudSpmReport::Fy2026::SpmEnrollment.create_enrollment_set(report)

    report
  end

  def run_measure(report, measure_class)
    report.started_at ||= Time.current
    report.save! if report.changed?

    generator = HudSpmReport::Generators::Fy2026::Generator.new(report)
    measure = measure_class.new(generator, report)
    measure.run_question!
    report.reload
  end

  # Optimized bulk insert for performance testing
  # Instead of individual creates (O(n) database calls), this method:
  # 1. Builds all records in memory
  # 2. Bulk imports clients (source + destination)
  # 3. Bulk imports warehouse_client links
  # 4. Bulk imports enrollments and exits
  # 5. Optionally bulk creates bed nights for ES Night-by-Night enrollments
  # This reduces database round trips from thousands to a handful
  def bulk_build_households(projects:, base_entry_date:, household_count:, members_per_household:, enrollments_per_member:, create_bed_nights: false)
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

    # Build all enrollment and exit records in memory
    enrollments = []
    exits = []

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
            move_in_date: relationship == 1 ? entry_date : nil,
            enrollment_coc: project_coc_codes[project_index],
          )
          enrollments << enrollment

          exit_record = build(
            :hud_exit,
            personal_id: client.personal_id,
            data_source_id: data_source.id,
            exit_date: exit_date,
            destination: 301,
          )
          exits << exit_record
        end
      end
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
    return unless create_bed_nights

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
end
