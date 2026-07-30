###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Benchmarking::Dataset, type: :model do
  # Test design: Tier 3 — dataset identity underpins comparability of benchmark
  # results across runs/branches. Real files on disk, exact-value assertions;
  # includes the mutation case (changed content => changed hash).
  let(:root) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(root)
  end

  def write_csv(dir, name, content)
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, name), content)
  end

  describe 'csv_dir' do
    it 'uses the source/ subdirectory when present, matching fixture layout' do
      write_csv(File.join(root, 'source'), 'Client.csv', "PersonalID\n1\n")

      expect(described_class.new(root).csv_dir).to eq(File.join(root, 'source'))
    end

    it 'uses the dataset path itself when there is no source/ subdirectory' do
      write_csv(root, 'Client.csv', "PersonalID\n1\n")

      expect(described_class.new(root).csv_dir).to eq(root)
    end
  end

  describe 'content_hash' do
    it 'is stable for identical content in different directories' do
      dir_a = File.join(root, 'a')
      dir_b = File.join(root, 'b')
      write_csv(dir_a, 'Client.csv', "PersonalID\n1\n")
      write_csv(dir_a, 'Export.csv', "ExportID\nEX1\n")
      write_csv(dir_b, 'Client.csv', "PersonalID\n1\n")
      write_csv(dir_b, 'Export.csv', "ExportID\nEX1\n")

      expect(described_class.new(dir_a).content_hash).to eq(described_class.new(dir_b).content_hash)
    end

    it 'changes when file content changes' do
      dir_a = File.join(root, 'a')
      dir_b = File.join(root, 'b')
      write_csv(dir_a, 'Client.csv', "PersonalID\n1\n")
      write_csv(dir_b, 'Client.csv', "PersonalID\n2\n")

      expect(described_class.new(dir_a).content_hash).not_to eq(described_class.new(dir_b).content_hash)
    end

    it 'changes when a file is renamed' do
      dir_a = File.join(root, 'a')
      dir_b = File.join(root, 'b')
      write_csv(dir_a, 'Client.csv', "PersonalID\n1\n")
      write_csv(dir_b, 'Clients.csv', "PersonalID\n1\n")

      expect(described_class.new(dir_a).content_hash).not_to eq(described_class.new(dir_b).content_hash)
    end
  end

  describe 'to_h' do
    it 'reports name, path, and content hash' do
      dir = File.join(root, 'my_dataset')
      write_csv(dir, 'Client.csv', "PersonalID\n1\n")
      dataset = described_class.new(dir)

      expect(dataset.to_h).to eq(
        name: 'my_dataset',
        path: dir,
        content_hash: dataset.content_hash,
      )
      expect(dataset.to_h[:content_hash]).to match(/\A[0-9a-f]{32}\z/)
    end
  end
end
