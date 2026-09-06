###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# rubyzip 3 dropped Zip::File::CREATE, so a call site that misses the create:
# true keyword can no longer open an archive that doesn't exist yet.
#
# Include alongside the 'a directory of files to archive' shared context. The
# includer defines archive!, which runs the code under test, and archive_path,
# where the archive lands.
RSpec.shared_examples 'creates a zip archive of a directory of files' do
  before(:each) { write_files(zip_directory, archive_entries) }

  it 'writes an archive holding every file, named without its directory prefix' do
    archive!

    expect(File.exist?(archive_path)).to be(true), "expected an archive at #{archive_path}"

    contents = Zip::File.open(archive_path) do |zipfile|
      zipfile.to_h { |entry| [entry.name, entry.get_input_stream.read] }
    end

    expect(contents).to eq(archive_entries)
  end
end
