###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Loader::HudKeyRemapper, type: :model do
  let(:loadable_files) do
    {
      'Client.csv' => HmisCsvTwentyTwentySix::Loader::Client,
      'Project.csv' => HmisCsvTwentyTwentySix::Loader::Project,
      'Enrollment.csv' => HmisCsvTwentyTwentySix::Loader::Enrollment,
      'Affiliation.csv' => HmisCsvTwentyTwentySix::Loader::Affiliation,
    }
  end

  def write_csv(dir, file_name, header, *rows)
    File.write(File.join(dir, file_name), ([header] + rows).map { |r| r.join(',') }.join("\n") + "\n")
  end

  def read_rows(dir, file_name)
    CSV.read(File.join(dir, file_name), headers: true).map(&:to_h)
  end

  it 'remaps a shared key identically across files' do
    Dir.mktmpdir do |dir|
      write_csv(dir, 'Client.csv', ['PersonalID'], ['C-1'])
      write_csv(dir, 'Enrollment.csv', ['EnrollmentID', 'PersonalID', 'HouseholdID'], ['E-1', 'C-1', 'H-1'])

      described_class.remap!(dir, loadable_files, 'SRC-1')

      expected = Digest::MD5.hexdigest('PersonalID--SRC-1--C-1')
      expect(read_rows(dir, 'Client.csv').first['PersonalID']).to eq(expected)
      expect(read_rows(dir, 'Enrollment.csv').first['PersonalID']).to eq(expected)
    end
  end

  it 'remaps HouseholdID even though no HUD file declares it as a hud_key' do
    Dir.mktmpdir do |dir|
      write_csv(dir, 'Enrollment.csv', ['EnrollmentID', 'PersonalID', 'HouseholdID'], ['E-1', 'C-1', 'H-1'])

      described_class.remap!(dir, loadable_files, 'SRC-1')

      expect(read_rows(dir, 'Enrollment.csv').first['HouseholdID']).to eq(Digest::MD5.hexdigest('HouseholdID--SRC-1--H-1'))
    end
  end

  it 'remaps ResProjectID in Affiliation.csv even though no HUD file declares it as a hud_key' do
    Dir.mktmpdir do |dir|
      write_csv(dir, 'Affiliation.csv', ['AffiliationID', 'ProjectID', 'ResProjectID'], ['A-1', 'P-1', 'P-2'])

      described_class.remap!(dir, loadable_files, 'SRC-1')

      row = read_rows(dir, 'Affiliation.csv').first
      expect(row['ResProjectID']).to eq(Digest::MD5.hexdigest('ResProjectID--SRC-1--P-2'))
      expect(row['ProjectID']).to eq(Digest::MD5.hexdigest('ProjectID--SRC-1--P-1'))
    end
  end

  it 'leaves blank values blank' do
    Dir.mktmpdir do |dir|
      write_csv(dir, 'Enrollment.csv', ['EnrollmentID', 'PersonalID', 'HouseholdID'], ['E-1', 'C-1', ''])

      described_class.remap!(dir, loadable_files, 'SRC-1')

      expect(read_rows(dir, 'Enrollment.csv').first['HouseholdID']).to be_nil
    end
  end

  it 'does not remap non-key columns' do
    Dir.mktmpdir do |dir|
      write_csv(dir, 'Client.csv', ['PersonalID', 'FirstName'], ['C-1', 'Pat'])

      described_class.remap!(dir, loadable_files, 'SRC-1')

      expect(read_rows(dir, 'Client.csv').first['FirstName']).to eq('Pat')
    end
  end

  describe 'the admin-extension interface' do
    it 'is checked only when pre_process_hooks[described_class.name] is set' do
      data_source = create(:data_source, pre_process_hooks: { 'HmisCsvImporter::Loader::HudKeyRemapper' => true })
      expect(described_class.checked?(data_source)).to eq(true)
      expect(described_class.checked?(create(:data_source))).to eq(false)
    end
  end
end
