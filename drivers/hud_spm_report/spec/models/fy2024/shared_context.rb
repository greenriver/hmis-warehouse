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
    project = create(:hud_project,
                     ProjectType: project_type,
                     organization: organization,
                     data_source: data_source,
                     ContinuumProject: 1)

    create(:hud_project_coc,
           ProjectID: project.ProjectID,
           data_source: data_source,
           CoCCode: coc_code)

    project
  end

  def create_client_with_warehouse_link
    client = create(:hud_client, PersonalID: SecureRandom.uuid, data_source: data_source)
    destination_client = create(:hud_client, data_source: destination_data_source)
    create(:warehouse_client, destination_id: destination_client.id, source_id: client.id)
    client
  end

  def create_enrollment(client:, project:, entry_date:, exit_date: nil, head_of_household: true,
    date_to_street_essh: nil, household_id: SecureRandom.uuid, living_situation: nil)
    enrollment = create(:hud_enrollment,
                        PersonalID: client.PersonalID,
                        project: project,
                        data_source: data_source,
                        EntryDate: entry_date,
                        DateToStreetESSH: date_to_street_essh,
                        RelationshipToHoH: head_of_household ? 1 : 3, # 1 = HoH, 3 = Child
                        HouseholdID: household_id,
                        LivingSituation: living_situation)

    if exit_date.present?
      create(:hud_exit,
             enrollment: enrollment,
             ExitDate: exit_date,
             data_source: data_source,
             PersonalID: client.PersonalID)
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
    generator = HudSpmReport::Generators::Fy2024::Generator.new(report)
    measure = measure_class.new(generator, report)
    measure.run_question!
    report.reload
  end
end
