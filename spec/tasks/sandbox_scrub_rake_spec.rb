###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'rake'

# sandbox:scrub — the CLI wrapper around SandboxMode::Scrubber. Scrub results are
# covered in the service spec; this pins the guard wiring.
RSpec.describe 'sandbox:scrub', type: :task do
  let(:task_name) { 'sandbox:scrub' }
  let!(:credential) { create(:grda_remote_s3, active: true) }

  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |t| t.name == 'sandbox:scrub' }
  end

  around do |example|
    original = ENV.fetch('SANDBOX_SCRUB_CONFIRM', nil)
    example.run
  ensure
    ENV['SANDBOX_SCRUB_CONFIRM'] = original
  end

  before { Rake::Task[task_name].reenable }

  def run_task
    Rake::Task[task_name].invoke
  end

  it 'aborts without confirmation and leaves credentials untouched' do
    ENV['SANDBOX_SCRUB_CONFIRM'] = nil

    with_sandbox_mode do
      expect { run_task }.to raise_error(SystemExit).and output(/confirm/i).to_stderr
    end
    expect(credential.reload.active).to be(true)
  end

  it 'aborts when sandbox mode is off even if confirmed' do
    ENV['SANDBOX_SCRUB_CONFIRM'] = Rails.env

    expect { run_task }.to raise_error(SystemExit).and output(/SANDBOX_MODE/).to_stderr
    expect(credential.reload.active).to be(true)
  end

  it 'scrubs when confirmed and in sandbox mode' do
    ENV['SANDBOX_SCRUB_CONFIRM'] = Rails.env

    with_sandbox_mode do
      expect { run_task }.to output(/rerun it; the scrub is idempotent.*remote_credentials: 1/m).to_stdout
    end
    expect(credential.reload.active).to be(false)
  end
end
