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

  def run_task(*args)
    Rake::Task[task_name].reenable
    Rake::Task[task_name].invoke(*args)
  end

  around do |example|
    original = ENV.fetch('SOURCE_TABLE', nil)
    example.run
  ensure
    original.nil? ? ENV.delete('SOURCE_TABLE') : ENV['SOURCE_TABLE'] = original
  end

  it 'defaults to a dry run of the default source with no limit' do
    ENV.delete('SOURCE_TABLE')
    run_task

    expect(HmisUtil::MigratedFileAttachmentLoader).to have_received(:new).with(
      source_table: HmisUtil::MigratedFileAttachmentLoader::DEFAULT_SOURCE_TABLE,
      dry_run: true,
      limit: nil,
    )
    expect(loader).to have_received(:run!)
  end

  it 'applies with a limit and a source table from SOURCE_TABLE' do
    ENV['SOURCE_TABLE'] = 'hmis_migration.other_file_attachments_to_load'
    run_task('false', '25')

    expect(HmisUtil::MigratedFileAttachmentLoader).to have_received(:new).with(
      source_table: 'hmis_migration.other_file_attachments_to_load',
      dry_run: false,
      limit: 25,
    )
  end

  it 'refuses a dry_run value other than true or false' do
    expect { run_task('yes') }.to raise_error(RuntimeError, /dry_run/)
    expect(HmisUtil::MigratedFileAttachmentLoader).not_to have_received(:new)
  end

  it 'refuses a limit that is not a positive integer' do
    expect { run_task('true', '10x') }.to raise_error(RuntimeError, /limit/)
    expect(HmisUtil::MigratedFileAttachmentLoader).not_to have_received(:new)
  end
end
