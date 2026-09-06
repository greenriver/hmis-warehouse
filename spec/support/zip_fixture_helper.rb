###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'zip'

# Helpers for the specs that cover the rubyzip 3 call sites.
module ZipFixtureHelper
  # entries is a hash of entry name => contents; names may include directories
  # (Client.csv, extra/Client.csv).
  def build_zip(path, entries)
    FileUtils.mkdir_p(File.dirname(path))
    FileUtils.rm_f(path)
    Zip::File.open(path, create: true) do |zipfile|
      entries.each do |name, contents|
        zipfile.get_output_stream(name) { |stream| stream.write(contents) }
      end
    end
    path
  end

  # The same entries as loose files, for call sites that zip a directory up
  # rather than extract one.
  def write_files(dir, entries)
    FileUtils.mkdir_p(dir)
    entries.each { |name, contents| File.write(File.join(dir, name), contents) }
    dir
  end

  def zip_entry_names(path)
    Zip::File.open(path) { |zipfile| zipfile.map(&:name) }
  end

  # Attach an archive to a record's hmis_zip and save it.
  def attach_hmis_zip(record, path, filename:, content_type: 'application/zip')
    record.hmis_zip.attach(io: File.open(path), filename: filename, content_type: content_type)
    record.save!
    record
  end

  def expect_no_leaked_files(names)
    names.each do |name|
      expect(File.exist?(File.join(Dir.pwd, name))).to be(false),
                                                       "#{name} leaked into #{Dir.pwd}; the call site is missing destination_directory:"
    end
  end

  # Clean up after a regressed call site so leaked files don't trip up the
  # next example.
  def remove_leaked_files(names)
    names.each { |name| FileUtils.rm_f(File.join(Dir.pwd, name)) }
  end

  # Minimal HUD CSV content, keyed by names GrdaWarehouse::Hud.hud_filename_to_model
  # recognizes.
  def hud_csv_entries
    {
      'Client.csv' => "PersonalID\nspec-client\n",
      'Enrollment.csv' => "EnrollmentID\nspec-enrollment\n",
    }
  end
end

RSpec.configure do |config|
  config.include ZipFixtureHelper
end
