###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../../spec/shared_contexts/hud_enrollment_builders'

# 9014 item 2. PATH reads HUD source tables client by client for the whole run, so an import can
# change them underneath it. These examples pin how many queries each client costs (a shorter run
# overlaps nightly processing less often) and that each client's row comes from one read of the
# client's enrollments.
#
# Transactional: the report and the writes it races with are sequential in one session.
RSpec.describe HudPathReport::Generators::Fy2026::QuestionEightToSixteen, type: :model, exclude_fixpoints: true do
  include_context 'HUD enrollment builders'

  let(:report_start) { Date.new(2025, 10, 1) }
  let(:report_end) { Date.new(2026, 9, 30) }
  let(:util) { HudHelper.util('2026') }
  let(:street_outreach) { util.project_type_number_from_code(:so).first }
  let(:path_funder_code) { HudPathReport::Generators::Fy2026::Base::PATH_FUNDER_CODE }
  let!(:path_project) do
    project = create_project(project_type: street_outreach)
    create(
      :hud_funder,
      ProjectID: project.ProjectID,
      data_source_id: data_source.id,
      Funder: path_funder_code,
      StartDate: Date.new(2020, 1, 1),
    )
    project
  end
  # In the report's project types, but not PATH-funded
  let!(:other_project) { create_project(project_type: street_outreach) }

  def create_path_client
    client = create_client_with_warehouse_link
    create_path_enrollment(client: client, entry_date: Date.new(2025, 11, 1), contact_date: Date.new(2025, 12, 1))
    client
  end

  # An enrollment that is active in PATH through one contact (a Current Living Situation and a PATH
  # service on the same day). Its contact dates are the PATH status date and that contact date.
  def create_path_enrollment(client:, entry_date:, contact_date:)
    enrollment = create_enrollment(
      client: client,
      project: path_project,
      entry_date: entry_date,
      ClientEnrolledInPATH: 1,
      DateOfPATHStatus: entry_date,
    )
    create(
      :hud_current_living_situation,
      data_source_id: data_source.id,
      EnrollmentID: enrollment.EnrollmentID,
      PersonalID: client.PersonalID,
      InformationDate: contact_date,
    )
    create(
      :hud_service,
      data_source_id: data_source.id,
      EnrollmentID: enrollment.EnrollmentID,
      PersonalID: client.PersonalID,
      DateProvided: contact_date,
      RecordType: util.record_type('PATH Service', true),
      TypeProvided: 1,
    )
    enrollment
  end

  def create_non_path_client
    client = create_client_with_warehouse_link
    create_enrollment(client: client, project: other_project, entry_date: Date.new(2025, 11, 1))
    client
  end

  def build_service_history
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
  end

  def new_report
    filter = Filters::HudFilterBase.new(
      user: User.setup_system_user,
      start: report_start,
      end: report_end,
      coc_codes: ['MA-500'],
      project_type_codes: util.path_project_type_codes,
      enforce_one_year_range: false,
    )
    generator_class = HudPathReport::Generators::Fy2026::Generator
    report = HudReports::ReportInstance.from_filter(
      filter,
      generator_class.title,
      build_for_questions: [described_class.question_number],
    )
    report.update!(question_names: [described_class.question_number], started_at: Time.current)
    report
  end

  def question_for(report)
    generator = HudPathReport::Generators::Fy2026::Generator.new(report)
    described_class.new(generator, report)
  end

  def path_clients(report)
    HudPathReport::Fy2020::PathClient.where(report_instance_id: report.id)
  end

  describe 'query cost of adding clients' do
    # The budget covers add_clients, the per-client loop item 2 changes. The question's own cell
    # queries are left out because they don't depend on how clients are loaded. If the fix renames
    # add_clients, point this at its replacement.
    def queries_to_add_clients
      question = question_for(new_report)
      count_database_queries { question.send(:add_clients) }
    end

    before do
      create_path_client
      build_service_history
      # Warm-up run: the first run in a process loads things (roles, access groups) only once
      queries_to_add_clients
    end

    # Measured today with this fixture: 25 queries per PATH client (income benefits 7, PATH services
    # and referrals 5, enrollments 3, disabilities 2, exits 2, CLS exists? 2, and one each for
    # health/DV, project, client and CLS contact dates). The budget is set clearly below that, not
    # from a measurement of the fix. The fix session should measure the fixed count and tighten
    # this budget to it, so the count can't grow back.
    let(:queries_per_path_client_budget) { 15 }

    it 'adds each PATH client within a fixed query budget' do
      pending('9014 item 2: each PATH client re-reads its enrollment, services and income several times')
      2.times { create_path_client }
      build_service_history
      queries_for_three_clients = queries_to_add_clients

      3.times { create_path_client }
      build_service_history
      queries_for_six_clients = queries_to_add_clients

      queries_per_client = (queries_for_six_clients - queries_for_three_clients) / 3.0
      expect(queries_per_client).to be <= queries_per_path_client_budget
    end

    it 'adds no queries for clients in the selected project types who are not in a PATH-funded project' do
      pending('9014 item 2: the client list includes every client in the selected project types')
      queries_with_path_clients_only = queries_to_add_clients

      3.times { create_non_path_client }
      build_service_history
      queries_with_non_path_clients = queries_to_add_clients

      expect(queries_with_non_path_clients).to eq(queries_with_path_clients_only)
    end

    it 'reports PATH clients only' do
      3.times { create_non_path_client }
      build_service_history
      report = new_report

      question_for(report).run_question!

      expect(path_clients(report).count).to eq(1)
    end
  end

  # Seam: the report looks up the client's latest active PATH enrollment more than once. These
  # examples change the client's enrollments right after the first lookup, as an import running
  # alongside the report would.
  describe "when the client's enrollments change during the report run" do
    let!(:client) { create_path_client }
    let(:destination_id) { client.destination_client.id }
    let(:first_enrollment) { GrdaWarehouse::Hud::Enrollment.find_by!(PersonalID: client.PersonalID, data_source_id: data_source.id) }
    let(:report) { new_report }
    let(:question) { question_for(report) }

    before { build_service_history }

    # Returns a hash that records whether the change ran
    def after_first_enrollment_lookup(&change)
      state = { changed: false }
      allow(question).to receive(:last_active_enrollment).and_wrap_original do |original, report_client|
        enrollment = original.call(report_client)
        if report_client.id == destination_id && !state[:changed]
          change.call
          state[:changed] = true
        end
        enrollment
      end
      state
    end

    def client_row
      path_clients(report).find_by(destination_client_id: destination_id)
    end

    def expected_contacts_for(enrollment, contact_date:)
      [enrollment.EntryDate, contact_date]
    end

    it 'finishes without error when the enrollment it chose is deleted mid-run' do
      pending('9014 item 2: the second enrollment lookup finds nothing and path_contact_dates reads EntryDate on nil')
      expected_contacts = expected_contacts_for(first_enrollment, contact_date: Date.new(2025, 12, 1))
      state = after_first_enrollment_lookup do
        # The importer soft-deletes rows missing from an export with update_all
        GrdaWarehouse::Hud::Enrollment.where(id: first_enrollment.id).update_all(DateDeleted: Time.current)
      end

      expect { question.run_question! }.not_to raise_error

      expect(state[:changed]).to be(true)
      # If the client is reported, the row describes the one enrollment that was read
      if client_row
        expect(client_row.first_date_in_program).to eq(first_enrollment.EntryDate)
        expect(client_row.contacts).to match_array(expected_contacts)
      end
    end

    it 'describes one enrollment when a later enrollment appears mid-run' do
      pending('9014 item 2: contact dates come from a second enrollment lookup that sees the new enrollment')
      later_contact_date = Date.new(2026, 3, 15)
      later_entry_date = Date.new(2026, 3, 1)
      expected_contacts_by_entry_date = {
        first_enrollment.EntryDate => expected_contacts_for(first_enrollment, contact_date: Date.new(2025, 12, 1)),
        later_entry_date => [later_entry_date, later_contact_date],
      }
      state = after_first_enrollment_lookup do
        create_path_enrollment(client: client, entry_date: later_entry_date, contact_date: later_contact_date)
      end

      question.run_question!

      expect(state[:changed]).to be(true)
      described_entry_date = client_row.first_date_in_program
      expect(expected_contacts_by_entry_date.keys).to include(described_entry_date)
      expect(client_row.contacts).to match_array(expected_contacts_by_entry_date[described_entry_date])
    end

    it 'describes the latest active enrollment when nothing changes mid-run' do
      question.run_question!

      expect(client_row.first_date_in_program).to eq(first_enrollment.EntryDate)
      expected_contacts = expected_contacts_for(first_enrollment, contact_date: Date.new(2025, 12, 1))
      expect(client_row.contacts).to match_array(expected_contacts)
    end
  end
end
