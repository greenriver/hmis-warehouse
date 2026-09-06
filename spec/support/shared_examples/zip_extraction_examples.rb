###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# In rubyzip 3 an entry extracts relative to destination_directory, which
# defaults to the working directory, so a call site that doesn't pass one
# writes its files somewhere nobody looks.
#
# Include alongside the 'a zip file to extract' shared context. The includer
# defines extract!, which runs the code under test against zip_source.
RSpec.shared_examples 'extracts entries into the destination directory' do
  it 'writes every entry, and only those entries, into the destination directory' do
    extract!

    expect(Dir.children(destination_dir)).to match_array(extracted_names)
    expect_no_leaked_files(extracted_names)
  end
end
