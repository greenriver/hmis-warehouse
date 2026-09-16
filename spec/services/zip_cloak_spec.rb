###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Needs the zipcloak binary (zip in the app image and in CI).
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

    expect(Zip::File.open(encrypted) { |zip| zip.map(&:encrypted?) }).to all(be true)
  end

  # The password used to be interpolated into a generated expect script, where
  # Tcl metacharacters escaped the string they were supposed to sit in. It is
  # now terminal input, so it is only ever a password.
  # Short enough to stay under MAX_PASSWORD_LENGTH, so the canary is relative
  # and the example has to run from scratch_dir to see it.
  it 'treats a password holding Tcl and shell metacharacters as a password' do
    password = %(p"; exec sh -c {touch canary}; # `touch canary`)

    Dir.chdir(scratch_dir) do
      described_class.encrypt(source: source, destination: encrypted, password: password)
      described_class.decrypt(source: encrypted, destination: decrypted, password: password)
    end

    expect(File.exist?(File.join(scratch_dir, 'canary'))).to be false
    expect(zip_entry_names(decrypted)).to match_array(hud_csv_entries.keys)
  end

  # zipcloak re-prompts instead of exiting on an over-long password, so without
  # this the job waits on a prompt nothing will answer.
  it 'raises rather than hanging on a password zipcloak will not accept' do
    expect do
      described_class.encrypt(source: source, destination: encrypted, password: 'p' * (ZipCloak::MAX_PASSWORD_LENGTH + 1))
    end.to raise_error(ZipCloak::Error, /longer than/)
  end

  it 'raises when zipcloak cannot read the source' do
    expect do
      described_class.encrypt(source: File.join(scratch_dir, 'missing.zip'), destination: encrypted, password: 'pw')
    end.to raise_error(ZipCloak::Error)
  end
end
