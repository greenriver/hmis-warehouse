###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Scratch directories and a source zip for the specs covering the rubyzip 3
# call sites. Override zip_entries and nested_entry_name for a call site that
# expects something other than HUD CSVs; override destination_dir when the code
# under test derives its own destination, building it under scratch_dir so the
# cleanup still catches it.
RSpec.shared_context 'a zip file to extract' do
  let(:source_dir) { Dir.mktmpdir('zip-extraction-source') }
  let(:scratch_dir) { Dir.mktmpdir('zip-extraction-scratch') }
  let(:destination_dir) { scratch_dir }

  let(:zip_entries) { hud_csv_entries }
  # These call sites extract File.basename(entry.name), so a nested entry lands
  # beside the top level ones. Its basename must not collide with theirs — the
  # app sets Zip.on_exists_proc, so a collision silently overwrites.
  let(:nested_entry_name) { 'nested/Exit.csv' }
  let(:extracted_names) { zip_entries.keys + [File.basename(nested_entry_name)] }

  let(:zip_source) do
    build_zip(
      File.join(source_dir, 'source.zip'),
      zip_entries.merge(nested_entry_name => "ExitID\nspec-exit\n"),
    )
  end

  after(:each) do
    [source_dir, scratch_dir].each { |dir| FileUtils.remove_entry(dir) if File.exist?(dir) }
  end
end
