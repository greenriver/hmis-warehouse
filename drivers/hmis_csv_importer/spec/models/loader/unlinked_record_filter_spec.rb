###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Loader::UnlinkedRecordFilter, type: :model do
  let(:loader_log) { HmisCsvImporter::Loader::LoaderLog.create!(data_source_id: create(:data_source).id, status: :loading, summary: {}) }
  let(:loadable_files) do
    {
      'Client.csv' => HmisCsvTwentyTwentySix::Loader::Client,
      'Project.csv' => HmisCsvTwentyTwentySix::Loader::Project,
      'Enrollment.csv' => HmisCsvTwentyTwentySix::Loader::Enrollment,
      'Exit.csv' => HmisCsvTwentyTwentySix::Loader::Exit,
    }
  end

  def write_csv(dir, file_name, header, *rows)
    File.write(File.join(dir, file_name), ([header] + rows).map { |r| r.join(',') }.join("\n") + "\n")
  end

  def read_column(dir, file_name, column)
    CSV.read(File.join(dir, file_name), headers: true).map { |r| r[column] }
  end

  it 'strips an Enrollment with no matching PersonalID, and cascades to related files' do
    Dir.mktmpdir do |dir|
      write_csv(dir, 'Client.csv', ['PersonalID'], ['C-1'])
      write_csv(dir, 'Project.csv', ['ProjectID'], ['P-1'])
      write_csv(dir, 'Enrollment.csv', ['EnrollmentID', 'PersonalID', 'ProjectID'],
                ['E-1', 'C-1', 'P-1'],
                ['E-2', 'C-MISSING', 'P-1'])
      write_csv(dir, 'Exit.csv', ['EnrollmentID', 'ExitDate'],
                ['E-1', '2020-01-01'],
                ['E-2', '2020-01-02'])

      described_class.filter!(dir, loadable_files, loader_log)

      expect(read_column(dir, 'Enrollment.csv', 'EnrollmentID')).to eq(['E-1'])
      expect(read_column(dir, 'Exit.csv', 'EnrollmentID')).to eq(['E-1'])
    end
  end

  it 'strips an Enrollment with no matching ProjectID' do
    Dir.mktmpdir do |dir|
      write_csv(dir, 'Client.csv', ['PersonalID'], ['C-1'])
      write_csv(dir, 'Project.csv', ['ProjectID'], ['P-1'])
      write_csv(dir, 'Enrollment.csv', ['EnrollmentID', 'PersonalID', 'ProjectID'], ['E-1', 'C-1', 'P-MISSING'])

      described_class.filter!(dir, loadable_files, loader_log)

      expect(read_column(dir, 'Enrollment.csv', 'EnrollmentID')).to eq([])
      expect(loader_log.row_processing_notes.pluck(:reason)).to eq(['no_matching_project_id'])
    end
  end

  it 'reports no_matching_personal_id (not no_matching_project_id) when both PersonalID and ProjectID are invalid' do
    Dir.mktmpdir do |dir|
      write_csv(dir, 'Client.csv', ['PersonalID'], ['C-1'])
      write_csv(dir, 'Project.csv', ['ProjectID'], ['P-1'])
      write_csv(dir, 'Enrollment.csv', ['EnrollmentID', 'PersonalID', 'ProjectID'], ['E-1', 'C-MISSING', 'P-MISSING'])

      described_class.filter!(dir, loadable_files, loader_log)

      expect(loader_log.row_processing_notes.pluck(:reason)).to eq(['no_matching_personal_id'])
    end
  end

  it 'discards every enrollment when Client.csv is entirely absent from the source directory' do
    Dir.mktmpdir do |dir|
      write_csv(dir, 'Project.csv', ['ProjectID'], ['P-1'])
      write_csv(dir, 'Enrollment.csv', ['EnrollmentID', 'PersonalID', 'ProjectID'], ['E-1', 'C-1', 'P-1'])

      described_class.filter!(dir, loadable_files, loader_log)

      expect(read_column(dir, 'Enrollment.csv', 'EnrollmentID')).to eq([])
      expect(loader_log.row_processing_notes.pluck(:reason)).to eq(['no_matching_personal_id'])
    end
  end

  it 'logs each discarded row with its file name and reason' do
    Dir.mktmpdir do |dir|
      write_csv(dir, 'Client.csv', ['PersonalID'], ['C-1'])
      write_csv(dir, 'Project.csv', ['ProjectID'], ['P-1'])
      write_csv(dir, 'Enrollment.csv', ['EnrollmentID', 'PersonalID', 'ProjectID'],
                ['E-1', 'C-1', 'P-1'],
                ['E-2', 'C-MISSING', 'P-1'])
      write_csv(dir, 'Exit.csv', ['EnrollmentID', 'ExitDate'],
                ['E-1', '2020-01-01'],
                ['E-2', '2020-01-02'])

      described_class.filter!(dir, loadable_files, loader_log)

      notes = loader_log.row_processing_notes.order(:id)
      expect(notes.map { |n| [n.file_name, n.reason] }).to eq(
        [['Enrollment.csv', 'no_matching_personal_id'], ['Exit.csv', 'orphaned_child_record']],
      )
      expect(loader_log.summary['Enrollment.csv']['total_discarded']).to eq(1)
      expect(loader_log.summary['Exit.csv']['total_discarded']).to eq(1)
    end
  end

  it 'records the discarded row content in the canonical HUD column order' do
    Dir.mktmpdir do |dir|
      write_csv(dir, 'Client.csv', ['PersonalID'], ['C-1'])
      write_csv(dir, 'Project.csv', ['ProjectID'], ['P-1'])
      write_csv(dir, 'Enrollment.csv', ['EnrollmentID', 'PersonalID', 'ProjectID'],
                ['E-1', 'C-1', 'P-1'],
                ['E-2', 'C-MISSING', 'P-1'])

      described_class.filter!(dir, loadable_files, loader_log)

      headers = HmisCsvTwentyTwentySix::Loader::Enrollment.hud_csv_headers.map(&:to_s)
      note = loader_log.row_processing_notes.find_by(file_name: 'Enrollment.csv')
      decoded = CSV.parse_line(note.row)

      expect(decoded.length).to eq(headers.length)
      expect(decoded[headers.index('EnrollmentID')]).to eq('E-2')
      expect(decoded[headers.index('PersonalID')]).to eq('C-MISSING')
      expect(decoded[headers.index('ProjectID')]).to eq('P-1')
    end
  end

  it 'leaves Client.csv untouched, including a PersonalID with no enrollment at all' do
    Dir.mktmpdir do |dir|
      write_csv(dir, 'Client.csv', ['PersonalID'], ['C-1'], ['C-UNENROLLED'])
      write_csv(dir, 'Project.csv', ['ProjectID'], ['P-1'])
      write_csv(dir, 'Enrollment.csv', ['EnrollmentID', 'PersonalID', 'ProjectID'], ['E-1', 'C-1', 'P-1'])

      described_class.filter!(dir, loadable_files, loader_log)

      expect(read_column(dir, 'Client.csv', 'PersonalID')).to eq(['C-1', 'C-UNENROLLED'])
    end
  end

  describe 'the admin-extension interface' do
    it 'is checked only when pre_process_hooks[strip_unlinked_records] is set' do
      data_source = create(:data_source, pre_process_hooks: { 'HmisCsvImporter::Loader::UnlinkedRecordFilter' => true })
      expect(described_class.checked?(data_source)).to eq(true)
      expect(described_class.checked?(create(:data_source))).to eq(false)
    end
  end
end
