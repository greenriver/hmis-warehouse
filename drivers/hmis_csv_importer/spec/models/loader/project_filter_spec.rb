###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Loader::ProjectFilter, type: :model do
  def write_csv(dir, file_name, header, *rows)
    File.write(File.join(dir, file_name), ([header] + rows).map { |r| r.join(',') }.join("\n") + "\n")
  end

  def read_personal_ids(dir, file_name)
    CSV.read(File.join(dir, file_name), headers: true, header_converters: :downcase).map { |row| row['personalid'] }
  end

  describe '.filter' do
    it 'drops clients who are neither already in the warehouse nor enrolled in an allowed project' do
      data_source = create(:grda_warehouse_data_source)
      create(:whitelisted_projects_for_client, data_source_id: data_source.id, ProjectID: 'P-allowed')

      Dir.mktmpdir do |dir|
        write_csv(dir, 'Client.csv', ['PersonalID'], ['C-allowed'], ['C-disallowed'])
        write_csv(
          dir,
          'Enrollment.csv',
          ['EnrollmentID', 'PersonalID', 'ProjectID'],
          ['E-1', 'C-allowed', 'P-allowed'],
          ['E-2', 'C-disallowed', 'P-other'],
        )

        described_class.filter(dir, data_source.id)

        expect(read_personal_ids(dir, 'Client.csv')).to contain_exactly('C-allowed')
      end
    end

    it 'keeps a client already in the warehouse even without a currently allowed enrollment' do
      data_source = create(:grda_warehouse_data_source)
      create(:hud_client, data_source: data_source, PersonalID: 'C-returning')

      Dir.mktmpdir do |dir|
        write_csv(dir, 'Client.csv', ['PersonalID'], ['C-returning'])
        write_csv(dir, 'Enrollment.csv', ['EnrollmentID', 'PersonalID', 'ProjectID'], ['E-1', 'C-returning', 'P-other'])

        described_class.filter(dir, data_source.id)

        expect(read_personal_ids(dir, 'Client.csv')).to contain_exactly('C-returning')
      end
    end
  end

  describe 'combined with HudKeyRemapper (both pre-process hooks enabled)' do
    let(:loadable_files) do
      {
        'Client.csv' => HmisCsvTwentyTwentySix::Loader::Client,
        'Project.csv' => HmisCsvTwentyTwentySix::Loader::Project,
        'Enrollment.csv' => HmisCsvTwentyTwentySix::Loader::Enrollment,
      }
    end
    let(:source_id) { 'SRC-1' }

    def remapped(column, value)
      HmisCsvImporter::Loader::HudKeyRemapper.remap_value(column, source_id, value)
    end

    it 'still recognizes returning clients and allowed projects once IDs are hashed' do
      data_source = create(:grda_warehouse_data_source)
      create(:whitelisted_projects_for_client, data_source_id: data_source.id, ProjectID: 'P-allowed')
      create(:hud_client, data_source: data_source, PersonalID: remapped('PersonalID', 'C-returning'))

      Dir.mktmpdir do |dir|
        write_csv(dir, 'Client.csv', ['PersonalID'], ['C-returning'], ['C-new-allowed'], ['C-new-disallowed'])
        write_csv(
          dir,
          'Enrollment.csv',
          ['EnrollmentID', 'PersonalID', 'ProjectID'],
          ['E-1', 'C-returning', 'P-other'],
          ['E-2', 'C-new-allowed', 'P-allowed'],
          ['E-3', 'C-new-disallowed', 'P-other'],
        )

        HmisCsvImporter::Loader::HudKeyRemapper.remap!(dir, loadable_files, source_id)
        described_class.filter(dir, data_source.id, remap_source_id: source_id)

        expect(read_personal_ids(dir, 'Client.csv')).to contain_exactly(
          remapped('PersonalID', 'C-returning'),
          remapped('PersonalID', 'C-new-allowed'),
        )
      end
    end

    it 'fails to recognize an allowed project when the whitelist is not hashed the same way' do
      data_source = create(:grda_warehouse_data_source)
      create(:whitelisted_projects_for_client, data_source_id: data_source.id, ProjectID: 'P-allowed')

      Dir.mktmpdir do |dir|
        write_csv(dir, 'Client.csv', ['PersonalID'], ['C-new-allowed'])
        write_csv(dir, 'Enrollment.csv', ['EnrollmentID', 'PersonalID', 'ProjectID'], ['E-1', 'C-new-allowed', 'P-allowed'])

        HmisCsvImporter::Loader::HudKeyRemapper.remap!(dir, loadable_files, source_id)
        described_class.filter(dir, data_source.id)

        expect(read_personal_ids(dir, 'Client.csv')).to be_empty
      end
    end
  end
end
