###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# rubyzip 3 changed Zip::Entry#extract: the first argument is now a path
# relative to destination_directory (default '.'), so an absolute first
# argument is joined onto the working directory instead of being honored.
# Every call site therefore has to pass destination_directory:. Including
# these examples pins that down -- drop the destination_directory: argument
# from the call site under test and the second example fails because the
# entries land in Dir.pwd.
#
# Include alongside the 'a zip file to extract' shared context, which supplies
# destination_dir and extracted_names. The includer defines extract!, which
# invokes the code under test against zip_source.
RSpec.shared_examples 'extracts entries into the destination directory' do
  after(:each) do
    # Belt and braces: if the call site regresses, don't leave the leaked
    # files behind in the repository for the next example to trip over.
    extracted_names.each { |name| FileUtils.rm_f(File.join(Dir.pwd, name)) }
  end

  it 'writes each entry under the destination directory' do
    extract!

    extracted_names.each do |name|
      expect(File.exist?(File.join(destination_dir, name))).to be(true),
                                                               "expected #{name} in #{destination_dir}, found #{Dir.glob(File.join(destination_dir, '*')).inspect}"
    end
  end

  it 'writes nothing into the working directory' do
    extract!

    extracted_names.each do |name|
      expect(File.exist?(File.join(Dir.pwd, name))).to be(false),
                                                       "#{name} leaked into #{Dir.pwd}; the call site is missing destination_directory:"
    end
  end

  it 'flattens the nested entry into the destination directory' do
    extract!

    expect(Dir.children(destination_dir)).to match_array(extracted_names)
  end
end
