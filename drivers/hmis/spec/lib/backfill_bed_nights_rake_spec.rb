###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'backfill_bed_nights rake task', type: :task do
  let(:task_name) { 'backfill_bed_nights' }
  let(:backfill) { instance_double(HmisUtil::BedNightBackfill, run!: nil) }

  before do
    Rake::Task.clear
    Rake.application = Rake::Application.new
    load Rails.root.join('drivers/hmis/lib/tasks/backfill_bed_nights.rake')
    Rake::Task.define_task(:environment)
    allow(HmisUtil::BedNightBackfill).to receive(:new).and_return(backfill)
  end

  def run_task(*args)
    Rake::Task[task_name].reenable
    Rake::Task[task_name].invoke(*args)
  end

  around do |example|
    original = ENV.fetch('PROJECT_IDS', nil)
    example.run
  ensure
    original.nil? ? ENV.delete('PROJECT_IDS') : ENV['PROJECT_IDS'] = original
  end

  it 'defaults to a dry run and parses comma-separated project ids' do
    ENV['PROJECT_IDS'] = '12, 34,56'
    run_task
    expect(HmisUtil::BedNightBackfill).to have_received(:new).with(project_pks: [12, 34, 56], dry_run: true)
    expect(backfill).to have_received(:run!)
  end

  it 'applies when dry_run is false' do
    ENV['PROJECT_IDS'] = '12'
    run_task('false')
    expect(HmisUtil::BedNightBackfill).to have_received(:new).with(project_pks: [12], dry_run: false)
  end

  it 'refuses to run without project ids' do
    ENV.delete('PROJECT_IDS')
    expect { run_task }.to raise_error(RuntimeError, /PROJECT_IDS/)
    expect(HmisUtil::BedNightBackfill).not_to have_received(:new)
  end

  it 'refuses a dry_run value other than true or false' do
    ENV['PROJECT_IDS'] = '12'
    expect { run_task('yes') }.to raise_error(RuntimeError, /dry_run/)
  end

  it 'refuses non-numeric project ids' do
    ENV['PROJECT_IDS'] = '12,abc'
    expect { run_task }.to raise_error(RuntimeError, /PROJECT_IDS/)
  end
end
