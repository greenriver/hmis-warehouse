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
        result = described_class.new(patient: patient, user: user).export(path: tmpdir)

        expect(result).to have_key(:exported)
        expect(result).to have_key(:skipped)

        expect(result[:skipped]).to be_empty

        Health::ExportPatient::EXPORT_CONFIGS.each do |config|
          subdir = File.join(tmpdir, config[:subdir])
          expect(Dir.exist?(subdir)).to be(true), "expected subdir #{config[:subdir]} to exist"
        end

        expect(Dir[File.join(tmpdir, 'health_careplans', '*.pdf')].count).to eq(1)
        expect(Dir[File.join(tmpdir, 'health_pctp_careplans', '*.pdf')].count).to eq(1)
        expect(Dir[File.join(tmpdir, 'health_comprehensive_health_assessments', '*.pdf')].count).to eq(1)
        expect(Dir[File.join(tmpdir, 'health_comprehensive_assessments', '*.pdf')].count).to eq(1)
        expect(Dir[File.join(tmpdir, 'health_ssm_forms', '*.pdf')].count).to eq(1)
        expect(Dir[File.join(tmpdir, 'health_thrive_assessments', '*.pdf')].count).to eq(1)
        expect(Dir[File.join(tmpdir, 'health_participation_forms', '*.pdf')].count).to eq(1)
        expect(Dir[File.join(tmpdir, 'health_release_forms', '*.pdf')].count).to eq(1)
        expect(Dir[File.join(tmpdir, 'health_sdh_case_management_notes', '*.pdf')].count).to eq(1)

        careplan_file = Dir[File.join(tmpdir, 'health_careplans', '*.pdf')].first
        expect(File.basename(careplan_file)).to eq("#{careplan.id}-careplan.pdf")
        expect(File.binread(careplan_file)).to eq(fake_pdf)

        expect(result[:exported].count).to eq(9)
      end
    end

    it 'skips records when the generator returns nil and adds them to skipped' do
      allow(Health::DocumentExports::CareplanPdfExport).to(
        receive(:generate).and_return(nil),
      )

      Dir.mktmpdir do |tmpdir|
        result = described_class.new(patient: patient, user: user).export(path: tmpdir)

        expect(result[:skipped]).to include("careplan##{careplan.id}")
        expect(result[:exported].count).to eq(8)
        expect(Dir[File.join(tmpdir, 'health_careplans', '*.pdf')]).to be_empty
      end
    end
  end
end
