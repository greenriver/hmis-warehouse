###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'tempfile'
require 'fileutils'

RSpec.describe AcHmis::ImportLinkNarrative20260318 do
  let!(:remote_credential) { create(:ac_hmis_warehouse_credential) }
  let!(:data_source) { create(:hmis_data_source) }
  let!(:organization) { create(:hmis_hud_organization, data_source: data_source) }
  let!(:link_project) do
    create(:hmis_hud_project, data_source: data_source, organization: organization, with_coc: true)
  end
  let!(:client) { create(:hmis_hud_client, data_source: data_source) }
  let!(:mci_uniq_external_id) { create(:mci_unique_id_external_id, source: client, value: 'MCI12345', remote_credential: remote_credential) }
  let!(:contact_method_cded) { create(:hmis_custom_data_element_definition, owner_type: Hmis::Hud::CustomCaseNote.name, key: described_class::CONTACT_METHOD_CDED_KEY, data_source: data_source) }
  let!(:system_user) { Hmis::Hud::User.system_user(data_source_id: data_source.id) }

  let(:contact_date_str) { '1/3/2022 8:06:00 AM' }
  let(:contact_date) { Time.zone.parse(contact_date_str).to_date }

  def build_xlsx_file(rows)
    path = Tempfile.new(['link_narrative', '.xlsx']).path
    Axlsx::Package.new do |package|
      package.workbook.add_worksheet(name: 'Sheet1') do |sheet|
        sheet.add_row ['MCI_UNIQ_ID', 'CONTACT_DATE', 'CONTACT_TYPE', 'NOTES']
        rows.each do |r|
          sheet.add_row [r.fetch(:mci), r.fetch(:contact_date), r.fetch(:contact_type), r.fetch(:notes)]
        end
      end
      package.serialize(path)
    end
    path
  end

  def run_import!(path, dry_run: false)
    described_class.new(path, link_project.id, dry_run: dry_run).perform
  end

  describe 'dry run' do
    it 'does not create enrollments, case notes, or CDEs' do
      rows = [
        {
          mci: mci_uniq_external_id.value,
          contact_date: contact_date_str,
          contact_type: 'Phone',
          notes: 'Hello',
        },
      ]
      xlsx = build_xlsx_file(rows)

      counts = lambda do
        [Hmis::Hud::Enrollment.count, Hmis::Hud::CustomCaseNote.count, Hmis::Hud::CustomDataElement.count]
      end
      before_counts = counts.call
      run_import!(xlsx, dry_run: true)
      expect(counts.call).to eq(before_counts)
    ensure
      FileUtils.rm_f(xlsx)
    end
  end

  describe 'idempotency' do
    it 'does not duplicate enrollments, case notes, or CDEs on a second import of the same file' do
      rows = [
        {
          mci: mci_uniq_external_id.value,
          contact_date: contact_date_str,
          contact_type: 'Phone',
          notes: 'Same note',
        },
      ]
      xlsx = build_xlsx_file(rows)

      expect do
        run_import!(xlsx)
      end.to change { client.enrollments.count }.by(1).
        and change(Hmis::Hud::CustomCaseNote, :count).by(1).
        and change(Hmis::Hud::CustomDataElement.of_type(contact_method_cded), :count).by(1)

      # Re-run same import, expect no changes
      xlsx = build_xlsx_file(rows)
      expect do
        run_import!(xlsx)
      end.to not_change(Hmis::Hud::Enrollment, :count).
        and(not_change(Hmis::Hud::CustomCaseNote, :count)).
        and(not_change(Hmis::Hud::CustomDataElement, :count))
    ensure
      FileUtils.rm_f(xlsx)
    end
  end

  describe 'enrollment resolution' do
    context 'when an enrollment already overlaps the contact date' do
      let!(:existing_enrollment) do
        create(
          :hmis_hud_enrollment,
          project: link_project,
          client: client,
          data_source: data_source,
          entry_date: Date.new(2022, 1, 1),
          exit_date: Date.new(2022, 12, 31),
        )
      end

      it 'reuses that enrollment and does not create another' do
        rows = [
          {
            mci: mci_uniq_external_id.value,
            contact_date: contact_date_str,
            contact_type: 'In Person',
            notes: 'Used existing enrollment',
          },
        ]
        xlsx = build_xlsx_file(rows)

        expect { run_import!(xlsx) }.
          to change(Hmis::Hud::Enrollment, :count).by(0).
          and(change(Hmis::Hud::CustomCaseNote, :count).by(1)).
          and(change(Hmis::Hud::CustomDataElement, :count).by(1))

        note = Hmis::Hud::CustomCaseNote.order(:id).last
        expect(note.EnrollmentID).to eq(existing_enrollment.enrollment_id)
      ensure
        FileUtils.rm_f(xlsx)
      end
    end

    context 'when no enrollment overlaps the contact date' do
      it 'creates a one-day enrollment with intake and exit assessments' do
        rows = [
          {
            mci: mci_uniq_external_id.value,
            contact_date: contact_date_str,
            contact_type: 'Email',
            notes: 'New enrollment path',
          },
        ]
        xlsx = build_xlsx_file(rows)

        expect do
          run_import!(xlsx)
        end.to change(Hmis::Hud::Enrollment, :count).by(1)

        enrollment = Hmis::Hud::Enrollment.order(:id).last
        expect(enrollment.project).to eq(link_project)
        expect(enrollment.entry_date).to eq(contact_date)
        expect(enrollment.intake_assessment.assessment_date).to eq(contact_date)
        expect(enrollment.intake_assessment.form_processor).to be_present
        expect(enrollment.exit_assessment.assessment_date).to eq(contact_date)
        expect(enrollment.exit_assessment.form_processor).to be_present
        expect(enrollment.exit.exit_date).to eq(contact_date)
      ensure
        FileUtils.rm_f(xlsx)
      end
    end
  end

  describe 'case note shape' do
    it 'persists expected HUD fields on CustomCaseNote' do
      rows = [
        {
          mci: mci_uniq_external_id.value,
          contact_date: contact_date_str,
          contact_type: 'Phone',
          notes: 'Case note body',
        },
      ]
      xlsx = build_xlsx_file(rows)

      run_import!(xlsx)

      note = client.custom_case_notes.sole
      enrollment = client.enrollments.sole

      expect(note.content).to eq('Case note body')
      expect(note.information_date).to eq(contact_date)
      expect(note.EnrollmentID).to eq(enrollment.enrollment_id)
      expect(note.PersonalID).to eq(client.personal_id)
      expect(note.data_source_id).to eq(data_source.id)
      expect(note.UserID).to eq(system_user.UserID)
      expect(note.CustomCaseNoteID).to match(/\A[a-f0-9]{32}\z/)
    ensure
      FileUtils.rm_f(xlsx)
    end
  end
end
