###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# CI provides an SFTP service for the test job (see hmis-warehouse-sftp in
# .github/workflows/rails_tests.yml). These examples stub upload calls. For live SFTP
# locally: docker compose up -d sftp

require 'rails_helper'

RSpec.describe Health::PatientsExporter, type: :model do
  let(:user) { create(:acl_user) }
  let(:patient) { create(:patient) }
  let(:other_patient) { create(:patient) }
  let(:config) do
    build(
      :mhx_sftp_credentials,
      path: '/sftp',
      kind: 'epic_data',
      active: true,
    )
  end
  let(:export_path) { 'tmp/health_patients_exporter_spec' }
  let(:destination_date) { Date.current.strftime('%Y-%m-%d') }

  describe '#initialize' do
    it 'builds the dated destination under the config path' do
      exporter = described_class.new(
        patients: Health::Patient.where(id: patient.id),
        configs: [config],
        path: export_path,
        destination: 'carehub_export',
        user: user,
      )

      expect(exporter.instance_variable_get(:@destination)).to eq(
        File.join('/sftp', 'carehub_export', destination_date),
      )
    end

    it 'uses the first active epic_data config when configs are omitted' do
      epic_config = create(
        :mhx_sftp_credentials,
        path: '/sftp/epic',
        kind: 'epic_data',
        active: true,
      )

      exporter = described_class.new(
        patients: Health::Patient.where(id: patient.id),
        path: export_path,
        user: user,
      )

      expect(exporter.instance_variable_get(:@config)).to eq(epic_config)
      expect(exporter.instance_variable_get(:@destination)).to eq(
        File.join('/sftp/epic', 'carehub_export', destination_date),
      )
    end
  end

  describe '#export' do
    let(:patient_folder) do
      Health::ExportPatient.new(patient: patient, user: user).export_folder
    end
    let(:local_file) do
      File.join(export_path, patient_folder, 'health_careplans', '1-careplan.pdf')
    end
    let(:second_local_file) do
      File.join(export_path, patient_folder, 'health_ssm_forms', '2-ssm.pdf')
    end
    let(:export_result) do
      { exported: [local_file], skipped: [], errors: [] }
    end
    let(:export_patient) { instance_double(Health::ExportPatient, export: export_result) }

    before do
      FileUtils.mkdir_p(File.dirname(local_file))
      File.binwrite(local_file, 'pdf')
      allow(Health::ExportPatient).to receive(:new).and_return(export_patient)
      allow(config).to receive(:put_with_mkdir_p)
    end

    after do
      FileUtils.rm_rf(export_path)
    end

    it 'uploads exported files and removes local copies' do
      exporter = described_class.new(
        patients: Health::Patient.where(id: patient.id),
        configs: [config],
        path: export_path,
        user: user,
      )
      result = exporter.export

      relative_path = local_file.delete_prefix("#{export_path}/")
      remote_path = File.join('/sftp', 'carehub_export', destination_date, relative_path)

      expect(config).to have_received(:put_with_mkdir_p).with(local_file, remote_path)
      expect(result[:uploaded]).to eq([relative_path])
      expect(result[:upload_errors]).to be_empty
      expect(File.exist?(local_file)).to be(false)
      expect(result[:exported]).to eq([export_result])
    end

    it 'does not upload when export produced no files' do
      allow(export_patient).to receive(:export).and_return({ exported: [], skipped: ['careplan#1'], errors: [] })

      exporter = described_class.new(
        patients: Health::Patient.where(id: patient.id),
        configs: [config],
        path: export_path,
        user: user,
      )
      result = exporter.export

      expect(config).not_to have_received(:put_with_mkdir_p)
      expect(result[:uploaded]).to be_empty
    end

    it 'records upload errors without stopping the export' do
      allow(config).to receive(:put_with_mkdir_p).and_raise(StandardError, 'upload failed')

      exporter = described_class.new(
        patients: Health::Patient.where(id: patient.id),
        configs: [config],
        path: export_path,
        user: user,
      )
      result = exporter.export

      relative_path = local_file.delete_prefix("#{export_path}/")
      expect(result[:uploaded]).to be_empty
      expect(result[:upload_errors]).to eq([{ file: relative_path, error: 'upload failed' }])
    end

    it 'uploads each exported file and records partial failures' do
      FileUtils.mkdir_p(File.dirname(second_local_file))
      File.binwrite(second_local_file, 'pdf')
      allow(export_patient).to receive(:export).and_return(
        { exported: [local_file, second_local_file], skipped: [], errors: [] },
      )
      allow(config).to receive(:put_with_mkdir_p).with(local_file, anything)
      allow(config).to receive(:put_with_mkdir_p).with(second_local_file, anything).and_raise(StandardError, 'second failed')

      exporter = described_class.new(
        patients: Health::Patient.where(id: patient.id),
        configs: [config],
        path: export_path,
        user: user,
      )
      result = exporter.export

      first_relative = local_file.delete_prefix("#{export_path}/")
      second_relative = second_local_file.delete_prefix("#{export_path}/")
      expect(result[:uploaded]).to eq([first_relative])
      expect(result[:upload_errors]).to eq([{ file: second_relative, error: 'second failed' }])
    end

    it 'exports each patient in the batch' do
      allow(Health::ExportPatient).to receive(:new).and_wrap_original do |method, **args|
        exporter = method.call(**args)
        file = File.join(
          export_path,
          exporter.export_folder,
          'health_careplans',
          "#{args[:patient].id}-careplan.pdf",
        )
        FileUtils.mkdir_p(File.dirname(file))
        File.binwrite(file, 'pdf')
        instance_double(
          Health::ExportPatient,
          export: { exported: [file], skipped: [], errors: [] },
        )
      end

      exporter = described_class.new(
        patients: Health::Patient.where(id: [patient.id, other_patient.id]),
        configs: [config],
        path: export_path,
        user: user,
      )
      result = exporter.export

      expect(Health::ExportPatient).to have_received(:new).twice
      expect(result[:exported].size).to eq(2)
      expect(result[:uploaded].size).to eq(2)
    end

    it 'resets upload tracking on each export call' do
      exporter = described_class.new(
        patients: Health::Patient.where(id: patient.id),
        configs: [config],
        path: export_path,
        user: user,
      )

      exporter.export

      FileUtils.mkdir_p(File.dirname(local_file))
      File.binwrite(local_file, 'pdf')
      second_result = exporter.export

      expect(second_result[:uploaded]).to eq([local_file.delete_prefix("#{export_path}/")])
      expect(second_result[:upload_errors]).to be_empty
    end

    it 'passes min_modification_date through to ExportPatient' do
      min_modification_date = '2024-06-01'

      exporter = described_class.new(
        patients: Health::Patient.where(id: patient.id),
        configs: [config],
        path: export_path,
        user: user,
        min_modification_date: min_modification_date,
      )
      exporter.export

      expect(Health::ExportPatient).to have_received(:new).with(
        hash_including(
          patient: patient,
          user: user,
          min_modification_date: min_modification_date,
        ),
      )
    end
  end
end
