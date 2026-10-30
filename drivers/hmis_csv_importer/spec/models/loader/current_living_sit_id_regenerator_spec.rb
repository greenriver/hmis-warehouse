###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Loader::CurrentLivingSitIdRegenerator, type: :model do
  let(:loader_log) { HmisCsvImporter::Loader::LoaderLog.create!(data_source_id: create(:grda_warehouse_data_source).id, status: :loading, summary: {}) }
  let(:loadable_files) do
    {
      'CurrentLivingSituation.csv' => HmisCsvTwentyTwentySix::Loader::CurrentLivingSituation,
      'Enrollment.csv' => HmisCsvTwentyTwentySix::Loader::Enrollment,
    }
  end
  let(:cls_header) { ['CurrentLivingSitID', 'EnrollmentID', 'PersonalID', 'InformationDate', 'CurrentLivingSituation', 'LocationDetails', 'DateCreated'] }
  let(:expected_id) { Digest::MD5.hexdigest('CurrentLivingSitID--E-1--C-1--2026-01-15--101--2026-01-15 09:30:00') }

  def write_csv(dir, file_name, header, *rows)
    File.write(File.join(dir, file_name), ([header] + rows).map { |r| r.join(',') }.join("\n") + "\n")
  end

  def read_rows(dir, file_name)
    CSV.read(File.join(dir, file_name), headers: true).map(&:to_h)
  end

  it 'replaces CurrentLivingSitID with the digest of EnrollmentID, PersonalID, InformationDate, CurrentLivingSituation, and DateCreated' do
    Dir.mktmpdir do |dir|
      write_csv(dir, 'CurrentLivingSituation.csv', cls_header, ['1', 'E-1', 'C-1', '2026-01-15', '101', 'Shelter', '2026-01-15 09:30:00'])

      described_class.regenerate!(dir, loadable_files, loader_log)

      expect(read_rows(dir, 'CurrentLivingSituation.csv').first['CurrentLivingSitID']).to eq(expected_id)
    end
  end

  it 'assigns each record the same ID when the file is reordered and renumbered' do
    row_a = ['E-1', 'C-1', '2026-01-15', '101', 'Shelter', '2026-01-15 09:30:00']
    row_b = ['E-1', 'C-1', '2026-02-20', '116', 'Street', '2026-02-20 14:00:00']

    Dir.mktmpdir do |dir|
      write_csv(dir, 'CurrentLivingSituation.csv', cls_header, ['1', *row_a], ['2', *row_b])
      described_class.regenerate!(dir, loadable_files, loader_log)
      first_load = read_rows(dir, 'CurrentLivingSituation.csv').to_h { |r| [r['InformationDate'], r['CurrentLivingSitID']] }

      write_csv(dir, 'CurrentLivingSituation.csv', cls_header, ['1', *row_b], ['2', *row_a])
      described_class.regenerate!(dir, loadable_files, loader_log)
      second_load = read_rows(dir, 'CurrentLivingSituation.csv').to_h { |r| [r['InformationDate'], r['CurrentLivingSitID']] }

      expect(first_load.values.uniq.size).to eq(2)
      expect(second_load).to eq(first_load)
    end
  end

  it 'gives distinct IDs to rows that differ only in DateCreated' do
    Dir.mktmpdir do |dir|
      write_csv(
        dir, 'CurrentLivingSituation.csv', cls_header,
        ['1', 'E-1', 'C-1', '2026-01-15', '101', 'Shelter', '2026-01-15 09:30:00'],
        ['2', 'E-1', 'C-1', '2026-01-15', '101', 'Shelter', '2026-01-15 16:45:00']
      )

      described_class.regenerate!(dir, loadable_files, loader_log)

      ids = read_rows(dir, 'CurrentLivingSituation.csv').map { |r| r['CurrentLivingSitID'] }
      expect(ids.size).to eq(2)
      expect(ids.uniq.size).to eq(2)
    end
  end

  it 'keeps the first of two rows with identical content and records the second as discarded' do
    Dir.mktmpdir do |dir|
      write_csv(
        dir, 'CurrentLivingSituation.csv', cls_header,
        ['1', 'E-1', 'C-1', '2026-01-15', '101', 'Shelter', '2026-01-15 09:30:00'],
        ['2', 'E-1', 'C-1', '2026-01-15', '101', 'Other shelter', '2026-01-15 09:30:00']
      )

      described_class.regenerate!(dir, loadable_files, loader_log)

      rows = read_rows(dir, 'CurrentLivingSituation.csv')
      expect(rows.map { |r| [r['CurrentLivingSitID'], r['LocationDetails']] }).to eq([[expected_id, 'Shelter']])
      expect(loader_log.row_processing_notes.pluck(:file_name, :reason)).to eq([['CurrentLivingSituation.csv', described_class::DUPLICATE_REASON]])
      expect(loader_log.summary['CurrentLivingSituation.csv']['total_discarded']).to eq(1)
    end
  end

  it 'leaves non-ID columns and other files unchanged' do
    Dir.mktmpdir do |dir|
      write_csv(dir, 'CurrentLivingSituation.csv', cls_header, ['1', 'E-1', 'C-1', '2026-01-15', '101', 'Shelter', '2026-01-15 09:30:00'])
      write_csv(dir, 'Enrollment.csv', ['EnrollmentID', 'PersonalID'], ['E-1', 'C-1'])
      enrollment_before = File.read(File.join(dir, 'Enrollment.csv'))

      described_class.regenerate!(dir, loadable_files, loader_log)

      row = read_rows(dir, 'CurrentLivingSituation.csv').first
      expect(row.except('CurrentLivingSitID')).to eq(
        'EnrollmentID' => 'E-1',
        'PersonalID' => 'C-1',
        'InformationDate' => '2026-01-15',
        'CurrentLivingSituation' => '101',
        'LocationDetails' => 'Shelter',
        'DateCreated' => '2026-01-15 09:30:00',
      )
      expect(File.read(File.join(dir, 'Enrollment.csv'))).to eq(enrollment_before)
    end
  end

  it 'matches headers case-insensitively' do
    Dir.mktmpdir do |dir|
      write_csv(dir, 'CurrentLivingSituation.csv', cls_header.map(&:downcase), ['1', 'E-1', 'C-1', '2026-01-15', '101', 'Shelter', '2026-01-15 09:30:00'])

      described_class.regenerate!(dir, loadable_files, loader_log)

      expect(read_rows(dir, 'CurrentLivingSituation.csv').first['currentlivingsitid']).to eq(expected_id)
    end
  end

  it 'leaves the directory untouched when CurrentLivingSituation.csv is absent' do
    Dir.mktmpdir do |dir|
      write_csv(dir, 'Enrollment.csv', ['EnrollmentID', 'PersonalID'], ['E-1', 'C-1'])

      described_class.regenerate!(dir, loadable_files, loader_log)

      expect(Dir.children(dir)).to eq(['Enrollment.csv'])
      expect(loader_log.row_processing_notes.count).to eq(0)
    end
  end

  it 'yields an ID that HudKeyRemapper then hashes with the SourceID' do
    Dir.mktmpdir do |dir|
      write_csv(dir, 'CurrentLivingSituation.csv', cls_header, ['1', 'E-1', 'C-1', '2026-01-15', '101', 'Shelter', '2026-01-15 09:30:00'])

      described_class.regenerate!(dir, loadable_files, loader_log)
      HmisCsvImporter::Loader::HudKeyRemapper.remap!(dir, loadable_files, 'SRC-1')

      row = read_rows(dir, 'CurrentLivingSituation.csv').first
      expect(row['CurrentLivingSitID']).to eq(HmisCsvImporter::Loader::HudKeyRemapper.remap_value('CurrentLivingSitID', 'SRC-1', expected_id))
      expect(row['EnrollmentID']).to eq(HmisCsvImporter::Loader::HudKeyRemapper.remap_value('EnrollmentID', 'SRC-1', 'E-1'))
    end
  end

  it 'reads a Windows-1252 file and writes it back as UTF-8' do
    Dir.mktmpdir do |dir|
      content = cls_header.join(',') + "\n" + ['1', 'E-1', 'C-1', '2026-01-15', '101', 'Café', '2026-01-15 09:30:00'].join(',') + "\n"
      File.binwrite(File.join(dir, 'CurrentLivingSituation.csv'), content.encode('Windows-1252'))

      described_class.regenerate!(dir, loadable_files, loader_log)

      row = read_rows(dir, 'CurrentLivingSituation.csv').first
      expect(row['CurrentLivingSitID']).to eq(expected_id)
      expect(row['LocationDetails']).to eq('Café')
    end
  end

  it 'tolerates a stray quote inside an unquoted field' do
    Dir.mktmpdir do |dir|
      File.write(
        File.join(dir, 'CurrentLivingSituation.csv'),
        cls_header.join(',') + "\n1,E-1,C-1,2026-01-15,101,Under 5th St \"bridge\",2026-01-15 09:30:00\n",
      )

      described_class.regenerate!(dir, loadable_files, loader_log)

      row = CSV.read(File.join(dir, 'CurrentLivingSituation.csv'), headers: true).first
      expect(row['CurrentLivingSitID']).to eq(expected_id)
      expect(row['LocationDetails']).to eq('Under 5th St "bridge"')
    end
  end

  it 'computes the same digest as Postgres md5 over concat_ws' do
    sql_value = GrdaWarehouseBase.connection.select_value(
      "SELECT md5(concat_ws('--', 'CurrentLivingSitID', 'E-1', 'C-1', '2026-01-15', '101', '2026-01-15 09:30:00'))",
    )
    ruby_value = described_class.digest(
      enrollment_id: 'E-1',
      personal_id: 'C-1',
      information_date: '2026-01-15',
      current_living_situation: '101',
      date_created: '2026-01-15 09:30:00',
    )

    expect(ruby_value).to eq(sql_value)
  end

  describe 'the admin-extension interface' do
    it 'is checked only when pre_process_hooks[described_class.name] is set' do
      data_source = create(:grda_warehouse_data_source, pre_process_hooks: { 'HmisCsvImporter::Loader::CurrentLivingSitIdRegenerator' => true })
      expect(described_class.checked?(data_source)).to eq(true)
      expect(described_class.checked?(create(:grda_warehouse_data_source))).to eq(false)
    end
  end
end
