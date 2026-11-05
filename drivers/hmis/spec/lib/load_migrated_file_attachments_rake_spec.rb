###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'load_migrated_file_attachments rake task', type: :task do
  let(:task_name) { 'load_migrated_file_attachments' }
  let(:loader) { instance_double(HmisUtil::MigratedFileAttachmentLoader, run!: nil) }

  before do
    Rake::Task.clear
    Rake.application = Rake::Application.new
    load Rails.root.join('drivers/hmis/lib/tasks/load_migrated_file_attachments.rake')
    Rake::Task.define_task(:environment)
    allow(HmisUtil::MigratedFileAttachmentLoader).to receive(:new).and_return(loader)
  end

  env_keys = ['SOURCE_TABLE', 'DRY_RUN', 'LIMIT', 'HEADSHOTS_ONLY']

  around do |example|
    original = env_keys.index_with { |key| ENV.fetch(key, nil) }
    env_keys.each { |key| ENV.delete(key) }
    example.run
  ensure
    original.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  def run_task(env = {})
    env.each { |key, value| ENV[key] = value }
    Rake::Task[task_name].reenable
    Rake::Task[task_name].invoke
  end

  it 'defaults to a dry run of the default source with no limit' do
    run_task

    expect(HmisUtil::MigratedFileAttachmentLoader).to have_received(:new).with(
      source_table: HmisUtil::MigratedFileAttachmentLoader::DEFAULT_SOURCE_TABLE,
      dry_run: true,
      limit: nil,
      headshots_only: false,
    )
    expect(loader).to have_received(:run!)
  end

  it 'applies with a limit, headshots only, and a source table from the environment' do
    run_task(
      'SOURCE_TABLE' => 'hmis_migration.other_file_attachments_to_load',
      'DRY_RUN' => 'false',
      'LIMIT' => '25',
      'HEADSHOTS_ONLY' => 'true',
    )

    expect(HmisUtil::MigratedFileAttachmentLoader).to have_received(:new).with(
      source_table: 'hmis_migration.other_file_attachments_to_load',
      dry_run: false,
      limit: 25,
      headshots_only: true,
    )
  end

  it 'treats blank values as unset' do
    run_task('DRY_RUN' => '', 'LIMIT' => '', 'HEADSHOTS_ONLY' => '')

    expect(HmisUtil::MigratedFileAttachmentLoader).to have_received(:new).with(hash_including(dry_run: true, limit: nil, headshots_only: false))
  end

  it 'refuses a HEADSHOTS_ONLY value other than true or false' do
    expect { run_task('HEADSHOTS_ONLY' => 'yes') }.to raise_error(RuntimeError, /HEADSHOTS_ONLY/)
    expect(HmisUtil::MigratedFileAttachmentLoader).not_to have_received(:new)
  end

  it 'refuses a DRY_RUN value other than true or false' do
    expect { run_task('DRY_RUN' => 'yes') }.to raise_error(RuntimeError, /DRY_RUN/)
    expect(HmisUtil::MigratedFileAttachmentLoader).not_to have_received(:new)
  end

  it 'refuses a LIMIT that is not a positive integer' do
    expect { run_task('LIMIT' => '10x') }.to raise_error(RuntimeError, /LIMIT/)
    expect(HmisUtil::MigratedFileAttachmentLoader).not_to have_received(:new)
  end
end
