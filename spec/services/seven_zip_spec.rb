###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SevenZip do
  let(:tmp_dir) { Dir.mktmpdir('seven-zip-spec') }

  after(:each) { FileUtils.remove_entry(tmp_dir) if File.exist?(tmp_dir) }

  # Builds a .7z holding the given archive-relative paths
  def build_archive(files, name: 'archive.7z')
    staging = File.join(tmp_dir, "staging-#{SecureRandom.hex(4)}")
    files.each do |path, contents|
      full = File.join(staging, path)
      FileUtils.mkdir_p(File.dirname(full))
      File.write(full, contents)
    end
    path = File.join(tmp_dir, name)
    described_class.create(destination: path, sources: Dir.glob(File.join(staging, '*'))) ||
      raise('unable to build the .7z fixture')
    path
  end

  describe '.create' do
    it 'writes an archive holding every source' do
      FileUtils.mkdir_p(File.join(tmp_dir, 'in'))
      ['Export.csv', 'Client.csv'].each { |n| File.write(File.join(tmp_dir, 'in', n), "a\n") }
      destination = File.join(tmp_dir, 'out.7z')

      expect(described_class.create(destination: destination, sources: Dir.glob(File.join(tmp_dir, 'in', '*')), level: 9)).
        to be true
      expect(described_class.entries(source: destination)).to contain_exactly('Export.csv', 'Client.csv')
    end

    it 'reports failure rather than raising, so the caller can say which record failed' do
      expect(described_class.create(destination: File.join(tmp_dir, 'out.7z'), sources: [])).to be false
    end
  end

  describe '.entries' do
    it 'lists archive-relative paths, including nested ones' do
      path = build_archive({ 'HMIS/Export.csv' => "a\n", 'HMIS/Client.csv' => "b\n" })

      expect(described_class.entries(source: path)).to contain_exactly('HMIS', 'HMIS/Export.csv', 'HMIS/Client.csv')
    end

    it 'returns nil for something that is not an archive' do
      path = File.join(tmp_dir, 'not-an-archive.7z')
      File.binwrite(path, 'plainly not a 7z')

      expect(described_class.entries(source: path)).to be_nil
    end

    it 'returns nil rather than raising when the binary is missing' do
      path = build_archive({ 'Export.csv' => "a\n" })
      stub_const("#{described_class}::BIN", 'definitely-not-a-real-binary')

      expect(described_class.entries(source: path)).to be_nil
    end
  end

  describe '.read_entry' do
    it 'streams a single member without expanding the archive' do
      path = build_archive({ 'Export.csv' => "SourceID\nMA-500\n" })

      expect(described_class.read_entry(source: path, entry: 'Export.csv', max_bytes: 1_000)).
        to eq("SourceID\nMA-500\n")
    end

    it 'stops at max_bytes instead of reading the whole member' do
      path = build_archive({ 'Export.csv' => 'x' * 50_000 })

      expect(described_class.read_entry(source: path, entry: 'Export.csv', max_bytes: 100).length).to eq(100)
    end

    # Past the cap 7z still has more to write, so the read has to end the process
    # rather than leave it blocked on a full pipe until the timeout expires.
    it 'returns promptly when the member is larger than the cap' do
      path = build_archive({ 'Export.csv' => 'x' * 5_000_000 })

      expect do
        Timeout.timeout(60) { described_class.read_entry(source: path, entry: 'Export.csv', max_bytes: 1_000) }
      end.not_to raise_error
    end

    it 'gives up at the timeout when 7z stalls before writing anything' do
      stalled = File.join(tmp_dir, 'stalled-7z')
      # exec, so the kill reaches the process holding stdout open
      File.write(stalled, "#!/bin/sh\nexec sleep 30\n")
      File.chmod(0o755, stalled)
      stub_const("#{described_class}::BIN", stalled)

      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      expect(described_class.read_entry(source: 'unused.7z', entry: 'Export.csv', max_bytes: 1_000, timeout: 1)).to be_nil
      expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).to be < 10
    end

    # 7z treats a member that isn't there as nothing to extract rather than an error,
    # which is why UploadValidityCheck looks the name up in .entries first.
    it 'returns an empty string for a member that is not in the archive' do
      path = build_archive({ 'Client.csv' => "a\n" })

      expect(described_class.read_entry(source: path, entry: 'Export.csv', max_bytes: 1_000)).to eq('')
    end
  end

  describe '.extract_all' do
    it 'expands every member into the destination' do
      path = build_archive({ 'Export.csv' => "a\n", 'Client.csv' => "b\n" })
      destination = File.join(tmp_dir, 'out')

      expect(described_class.extract_all(source: path, destination: destination)).to be true
      expect(Dir.glob(File.join(destination, '*')).map { |f| File.basename(f) }).
        to contain_exactly('Export.csv', 'Client.csv')
    end

    # An empty destination would be rezipped and saved over the user's upload, so the
    # caller raises on a false return rather than carrying on.
    it 'reports failure rather than leaving the destination empty' do
      path = File.join(tmp_dir, 'broken.7z')
      File.binwrite(path, 'plainly not a 7z')

      expect(described_class.extract_all(source: path, destination: File.join(tmp_dir, 'out'))).to be false
    end
  end
end
