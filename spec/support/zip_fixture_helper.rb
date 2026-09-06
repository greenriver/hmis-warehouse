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
