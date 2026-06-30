###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Health::ExportPatient, type: :model do
  let(:user) { create(:acl_user) }
  let(:patient) { create(:patient) }
  let(:exporter) { described_class.new(patient: patient, user: user) }
  let(:fake_pdf) { '%PDF-1.4 fake content' }

  let!(:careplan) { create(:careplan, patient: patient, user: user) }
  let!(:pctp) { create(:cp2_careplan, patient: patient, user: user) }
  let!(:cha) { create(:cha, patient: patient, user: user) }
  let!(:ca) { create(:health_ca, patient: patient, user: user) }
  let!(:ssm) { create(:ssm, patient: patient, user: user) }
  let!(:thrive) { create(:thrive, patient: patient, user: user) }
  let!(:participation_form) { create(:signed_participation_form, patient: patient) }
  let!(:release_form) { create(:release_form, patient: patient) }
  let!(:sdh_note) { create(:sdh_case_management_note, patient: patient, user: user) }

  before do
    allow(Health::DocumentExports::CareplanPdfExport).to(
      receive(:generate).and_return(fake_pdf),
    )
    allow(HealthPctp::DocumentExports::PctpCareplanPdfExport).to(
      receive(:generate).and_return(fake_pdf),
    )
    allow(Health::DocumentExports::SelfSufficiencyMatrixFormPdfExport).to(
      receive(:generate).and_return(fake_pdf),
    )
    allow(HealthThriveAssessment::DocumentExports::ThriveAssessmentPdfExport).to(
      receive(:generate).and_return(fake_pdf),
    )
    allow(HealthComprehensiveAssessment::DocumentExports::CaAssessmentPdfExport).to(
      receive(:generate).and_return(fake_pdf),
    )

    # Upload-only types: stub health_file on all instances so that records loaded
    # fresh from the DB (via association) also return content.
    health_file_double = instance_double('Health::HealthFile', content: fake_pdf, present?: true)
    allow_any_instance_of(Health::ComprehensiveHealthAssessment).to receive(:health_file).and_return(health_file_double)
    allow_any_instance_of(Health::ParticipationForm).to receive(:health_file).and_return(health_file_double)
    allow_any_instance_of(Health::ReleaseForm).to receive(:health_file).and_return(health_file_double)
    allow_any_instance_of(Health::SdhCaseManagementNote).to receive(:health_file).and_return(health_file_double)
  end

  describe '#export' do
    it 'creates subdirectories and writes one PDF file per association record' do
      Dir.mktmpdir do |tmpdir|
        result = exporter.export(path: tmpdir)

        expect(result).to have_key(:exported)
        expect(result).to have_key(:skipped)

        expect(result[:skipped]).to be_empty

        Health::ExportPatient::EXPORT_CONFIGS.each do |config|
          subdir = exporter.export_subdir(tmpdir, config[:subdir])
          expect(Dir.exist?(subdir)).to be(true), "expected subdir #{config[:subdir]} to exist"
        end

        folder = exporter.export_folder
        expect(Dir[File.join(tmpdir, folder, 'health_careplans', '*.pdf')].count).to eq(1)
        expect(Dir[File.join(tmpdir, folder, 'health_pctp_careplans', '*.pdf')].count).to eq(1)
        expect(Dir[File.join(tmpdir, folder, 'health_comprehensive_health_assessments', '*.pdf')].count).to eq(1)
        expect(Dir[File.join(tmpdir, folder, 'health_comprehensive_assessments', '*.pdf')].count).to eq(1)
        expect(Dir[File.join(tmpdir, folder, 'health_ssm_forms', '*.pdf')].count).to eq(1)
        expect(Dir[File.join(tmpdir, folder, 'health_thrive_assessments', '*.pdf')].count).to eq(1)
        expect(Dir[File.join(tmpdir, folder, 'health_participation_forms', '*.pdf')].count).to eq(1)
        expect(Dir[File.join(tmpdir, folder, 'health_release_forms', '*.pdf')].count).to eq(1)
        expect(Dir[File.join(tmpdir, folder, 'health_sdh_case_management_notes', '*.pdf')].count).to eq(1)

        careplan_file = Dir[File.join(tmpdir, folder, 'health_careplans', '*.pdf')].first
        expect(File.basename(careplan_file)).to eq(exporter.export_filename(careplan, label: 'careplan'))
        expect(File.binread(careplan_file)).to eq(fake_pdf)

        expect(result[:exported].count).to eq(9)
      end
    end

    it 'skips records when the generator returns nil and adds them to skipped' do
      allow(Health::DocumentExports::CareplanPdfExport).to(
        receive(:generate).and_return(nil),
      )

      Dir.mktmpdir do |tmpdir|
        result = exporter.export(path: tmpdir)

        expect(result[:skipped]).to include("careplan##{careplan.id}")
        expect(result[:exported].count).to eq(8)
        expect(Dir[File.join(tmpdir, exporter.export_folder, 'health_careplans', '*.pdf')]).to be_empty
      end
    end

    it 'skips records when the generator returns blank content' do
      allow(Health::DocumentExports::CareplanPdfExport).to(
        receive(:generate).and_return(''),
      )

      Dir.mktmpdir do |tmpdir|
        result = exporter.export(path: tmpdir)

        expect(result[:skipped]).to include("careplan##{careplan.id}")
        expect(result[:exported].count).to eq(8)
      end
    end

    it 'returns full file paths under the export root' do
      Dir.mktmpdir do |tmpdir|
        result = exporter.export(path: tmpdir)

        careplan_path = result[:exported].find { |path| path.include?('health_careplans') }
        expect(careplan_path).to eq(
          File.join(
            exporter.export_subdir(tmpdir, 'health_careplans'),
            exporter.export_filename(careplan, label: 'careplan'),
          ),
        )
      end
    end

    it 'includes an empty errors array on success' do
      Dir.mktmpdir do |tmpdir|
        result = exporter.export(path: tmpdir)

        expect(result[:errors]).to eq([])
      end
    end

    it 'uses patient id when medicaid_id is blank' do
      allow(patient).to receive(:medicaid_id).and_return(nil)

      Dir.mktmpdir do |tmpdir|
        result = exporter.export(path: tmpdir)

        subdir = exporter.export_subdir(tmpdir, 'health_careplans')
        expect(Dir.exist?(subdir)).to be(true)
        expect(result[:exported].count).to eq(9)
      end
    end

    it 'records generator failures in errors and continues exporting' do
      allow(Health::DocumentExports::CareplanPdfExport).to(
        receive(:generate).and_raise(StandardError, 'pdf failed'),
      )

      Dir.mktmpdir do |tmpdir|
        result = exporter.export(path: tmpdir)

        expect(result[:errors].map { |e| e[:ref] }).to include("careplan##{careplan.id}")
        expect(result[:errors].first[:message]).to eq('pdf failed')
        expect(result[:exported].count).to eq(8)
      end
    end

    context 'with min_modification_date' do
      let!(:old_careplan) do
        create(:careplan, patient: patient, user: user, created_at: 1.year.ago)
      end
      let(:min_modification_date) { 6.months.ago.strftime('%Y-%m-%d') }
      let(:exporter) do
        described_class.new(patient: patient, user: user, min_modification_date: min_modification_date)
      end

      it 'skips records modified strictly before min_modification_date' do
        Dir.mktmpdir do |tmpdir|
          result = exporter.export(path: tmpdir)

          exported_careplan_ids = result[:exported].
            grep(/health_careplans/).
            map { |path| File.basename(path).split('--').first.to_i }

          expect(exported_careplan_ids).to include(careplan.id)
          expect(exported_careplan_ids).not_to include(old_careplan.id)
          expect(result[:skipped]).not_to include("careplan##{old_careplan.id}")
          expect(result[:exported].count).to eq(9)
        end
      end

      it 'exports records modified on min_modification_date' do
        careplan.update!(created_at: Date.parse(min_modification_date))

        Dir.mktmpdir do |tmpdir|
          result = exporter.export(path: tmpdir)

          exported_careplan_ids = result[:exported].
            grep(/health_careplans/).
            map { |path| File.basename(path).split('--').first.to_i }

          expect(exported_careplan_ids).to include(careplan.id)
        end
      end

      it 'exports records when no modification date can be determined' do
        allow_any_instance_of(Health::ParticipationForm).to receive(:signature_on).and_return(nil)

        Dir.mktmpdir do |tmpdir|
          result = exporter.export(path: tmpdir)

          expect(result[:exported].grep(/health_participation_forms/)).not_to be_empty
        end
      end

      it 'does not call the generator for filtered records' do
        Dir.mktmpdir do |tmpdir|
          exporter.export(path: tmpdir)

          expect(Health::DocumentExports::CareplanPdfExport).to have_received(:generate).once
        end
      end
    end
  end
end
