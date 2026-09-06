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

# The loader exposes #expand(file_path:) writing to @local_path, which the class
# never assigns -- callers set it.
RSpec.shared_examples 'an HMIS CSV loader that expands into @local_path' do
  include_context 'a zip file to extract'

  let(:data_source) { create(:grda_warehouse_data_source) }

  let(:loader) do
    # The initializer needs a directory, and the loader reads Export.csv from it
    # to calculate the current version.
    csv_dir = File.join(scratch_dir, 'csvs')
    FileUtils.mkdir_p(csv_dir)
    File.write(File.join(csv_dir, 'Export.csv'), "ExportID,CSVVersion\nEX-1,2026\n")
    described_class.new(data_source_id: data_source.id, file_path: csv_dir, remove_files: false).tap do |instance|
      instance.instance_variable_set(:@local_path, destination_dir)
    end
  end

  # Separate from csv_dir above so the flattening assertion only sees
  # extracted entries.
  let(:destination_dir) { File.join(scratch_dir, 'expanded').tap { |dir| FileUtils.mkdir_p(dir) } }

  def extract!
    loader.send(:expand, file_path: zip_source)
  end

  include_examples 'extracts entries into the destination directory'

  it 'removes the source zip' do
    extract!

    expect(File.exist?(zip_source)).to be false
  end
end
