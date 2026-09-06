###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# In rubyzip 3 the first argument to Zip::Entry#extract is relative to
# destination_directory (default '.'), so an absolute path is joined onto the
# working directory rather than honored — every call site has to pass
# destination_directory:.
#
# Include alongside the 'a zip file to extract' shared context, which supplies
# destination_dir and extracted_names. The includer defines extract!, which
# invokes the code under test against zip_source.
RSpec.shared_examples 'extracts entries into the destination directory' do
  after(:each) { remove_leaked_files(extracted_names) }

  it 'writes each entry under the destination directory' do
    extract!

    extracted_names.each do |name|
      expect(File.exist?(File.join(destination_dir, name))).to be(true),
                                                               "expected #{name} in #{destination_dir}, found #{Dir.glob(File.join(destination_dir, '*')).inspect}"
    end
  end

  it 'writes nothing into the working directory' do
    extract!

    expect_no_leaked_files(extracted_names)
  end

  it 'flattens the nested entry into the destination directory' do
    extract!

    expect(Dir.children(destination_dir)).to match_array(extracted_names)
  end
end

# Both HMIS CSV loaders expose the same #expand(file_path:) writing to
# @local_path, which the class never assigns -- callers set it.
RSpec.shared_examples 'an HMIS CSV loader that expands into @local_path' do
  include_context 'a zip file to extract'

  let(:data_source) { create(:grda_warehouse_data_source) }

  let(:loader) do
    # The initializer needs a directory; the 2026 loader also reads Export.csv
    # from it to calculate the current version.
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
