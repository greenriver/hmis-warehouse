# frozen_string_literal: true

require 'rails_helper'

# Shared context for SPM testing
RSpec.shared_context 'SPM test setup', shared_context: :metadata do
  let(:user) { create(:user) }
  let(:default_filter) do
    Filters::HudFilterBase.new(
      user_id: user.id,
      start: '2022-10-01'.to_date,
      end: '2023-09-30'.to_date,
      coc_codes: ['MA-500'],
      enforce_one_year_range: false,
    )
  end

  let!(:destination_data_source) { create :destination_data_source }
  let!(:data_source) { create(:source_data_source) }

  # Setup CoC organization
  let!(:organization) { create(:hud_organization, data_source: data_source) }

  def create_project(project_type:, coc_code: 'MA-500')
    project = create(
      :hud_project,
      project_type: project_type,
      organization: organization,
      data_source: data_source,
      ContinuumProject: 1,
    )

    create(
      :hud_project_coc,
      project_id: project.project_id,
      data_source: data_source,
      coc_code: coc_code,
    )

    project
  end

  def create_client_with_warehouse_link(dob: '1995-04-05'.to_date)
    client = create(:hud_client, data_source: data_source, dob: dob)
    destination_client = create(:hud_client, data_source: destination_data_source)
    create(:warehouse_client, destination_id: destination_client.id, source_id: client.id)
    client
  end

  def create_enrollment(client:, project:, entry_date:, exit_date: nil, relationship_to_ho_h: 1, date_to_street_essh: nil, household_id: Hmis::Hud::Base.generate_uuid, living_situation: nil, destination: nil, move_in_date: nil)
    enrollment = create(
      :hud_enrollment,
      client: client,
      project: project,
      data_source: data_source,
      entry_date: entry_date,
      date_to_street_essh: date_to_street_essh,
      relationship_to_ho_h: relationship_to_ho_h,
      household_id: household_id,
      living_situation: living_situation,
      move_in_date: move_in_date,
    )

    if exit_date.present?
      create(
        :hud_exit,
        enrollment: enrollment,
        exit_date: exit_date,
        data_source: data_source,
        personal_id: client.personal_id,
        destination: destination,
      )
    end

    enrollment
  end

  def create_bed_night_service(enrollment:, date:)
    create(
      :hud_service,
      enrollment: enrollment,
      date_provided: date,
      data_source: data_source,
      record_type: 200, # bed night
    )
  end

  def setup_report(project_ids, questions = ['Measure 1'])
    filter = default_filter.dup
    filter.update(project_ids: project_ids)

    report = HudReports::ReportInstance.from_filter(
      filter,
      'System Performance Measures - FY 2024',
      build_for_questions: questions,
    )
    report.question_names = questions
    report.save!

    # Build ServiceHistoryEnrollments
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

    # Generate the SpmEnrollment records
    HudSpmReport::Fy2024::SpmEnrollment.create_enrollment_set(report)

    report
  end

  def run_measure(report, measure_class)
    report.started_at ||= Time.current
    report.save! if report.changed?

    generator = HudSpmReport::Generators::Fy2024::Generator.new(report)
    measure = measure_class.new(generator, report)
    measure.run_question!
    report.reload
  end
end
