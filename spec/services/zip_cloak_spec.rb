###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'timeout'
require 'rails_helper'

RSpec.describe ZipCloak do
  let(:scratch_dir) { Dir.mktmpdir('zip-cloak') }
  let(:source) { build_zip(File.join(scratch_dir, 'source.zip'), hud_csv_entries) }
  let(:encrypted) { File.join(scratch_dir, 'encrypted.zip') }
  let(:decrypted) { File.join(scratch_dir, 'decrypted.zip') }

  after(:each) { FileUtils.remove_entry(scratch_dir) if File.exist?(scratch_dir) }

  it 'round trips a zip through encrypt and decrypt' do
    described_class.encrypt(source: source, destination: encrypted, password: 'correct horse')
    described_class.decrypt(source: encrypted, destination: decrypted, password: 'correct horse')

    expect(zip_entry_names(decrypted)).to match_array(hud_csv_entries.keys)
    expect(Zip::File.open(decrypted) { |zip| zip.read('Client.csv') }).to eq(hud_csv_entries['Client.csv'])
  end

  it 'encrypts the entries it writes' do
    described_class.encrypt(source: source, destination: encrypted, password: 'correct horse')

    # Counted, not just `all`: `all` passes vacuously over the empty archive an
    # encrypt that quietly wrote nothing would leave behind.
    expect(Zip::File.open(encrypted) { |zip| zip.map(&:encrypted?) }).to eq([true] * hud_csv_entries.size)
  end

  it 'round trips a password at the length the models allow' do
    password = 'p' * ZipCloak::MAX_PASSWORD_LENGTH

    described_class.encrypt(source: source, destination: encrypted, password: password)
    described_class.decrypt(source: encrypted, destination: decrypted, password: password)

    expect(zip_entry_names(decrypted)).to match_array(hud_csv_entries.keys)
  end

  it 'rejects a password holding a line break rather than sending half of it' do
    ["pass\rword", "pass\nword", "password\n"].each do |password|
      expect do
        described_class.encrypt(source: source, destination: encrypted, password: password)
      end.to raise_error(ZipCloak::Error, /line break/)
    end
  end

  it 'treats a password holding Tcl and shell metacharacters as a password' do
    password = %(p"; exec sh -c {touch canary}; # `touch canary`)

    # The payload writes `canary` relative to the working directory, so the run has to
    # happen in scratch_dir for the assertion below to see a successful injection.
    Dir.chdir(scratch_dir) do
      described_class.encrypt(source: source, destination: encrypted, password: password)
      described_class.decrypt(source: encrypted, destination: decrypted, password: password)
    end

    expect(File.exist?(File.join(scratch_dir, 'canary'))).to be false
    expect(zip_entry_names(decrypted)).to match_array(hud_csv_entries.keys)
  end

  it 'raises rather than hanging on a password zipcloak will not accept' do
    expect do
      Timeout.timeout(30) do
        described_class.encrypt(source: source, destination: encrypted, password: 'p' * (ZipCloak::MAX_PASSWORD_LENGTH + 1))
      end
    end.to raise_error(ZipCloak::Error, /longer than/)
  end

  it 'raises rather than hanging when decryption gets a password zipcloak will not accept' do
    described_class.encrypt(source: source, destination: encrypted, password: 'correct horse')

    expect do
      Timeout.timeout(30) do
        described_class.decrypt(source: encrypted, destination: decrypted, password: 'p' * (ZipCloak::MAX_PASSWORD_LENGTH + 1))
      end
    end.to raise_error(ZipCloak::Error, /longer than/)
  end

  it 'raises when the password does not decrypt the archive' do
    described_class.encrypt(source: source, destination: encrypted, password: 'correct horse')

    expect do
      described_class.decrypt(source: encrypted, destination: decrypted, password: 'wrong horse')
    end.to raise_error(ZipCloak::Error, /wrong/)
  end

  it 'raises when zipcloak cannot read the source' do
    expect do
      Timeout.timeout(30) do
        described_class.encrypt(source: File.join(scratch_dir, 'missing.zip'), destination: encrypted, password: 'pw')
      end
    end.to raise_error(ZipCloak::Error)
  end

  it 'kills and reaps a child that never prompts' do
    stub_const('ZipCloak::PROMPT_TIMEOUT', 1)
    child_pid = nil
    # A real pty and a real child, just not zipcloak: nothing else prompts on demand
    # inside the shortened timeout.
    allow(PTY).to receive(:spawn).and_wrap_original do |original, *_args, &block|
      original.call('sleep', '30') do |reader, writer, pid|
        child_pid = pid
        block.call(reader, writer, pid)
      end
    end

    expect do
      described_class.encrypt(source: source, destination: encrypted, password: 'correct horse')
    end.to raise_error(ZipCloak::Error, /timed out waiting for the zipcloak password prompt/)

    expect(child_pid).to be_present
    expect { Process.waitpid(child_pid, Process::WNOHANG) }.to raise_error(Errno::ECHILD)
  end
end
