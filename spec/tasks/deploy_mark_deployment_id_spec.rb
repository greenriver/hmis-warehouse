###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'rake'

# system_status/details reports registered_deployment_id (written here) next to the
# running pod's `revision`, so operators can see whether deploy tasks have finished for
# the code that's serving. The two are only comparable if they're derived from the same
# thing, which is what this pins down.
RSpec.describe 'deploy:mark_deployment_id', type: :request do
  let(:task_name) { 'deploy:mark_deployment_id' }
  # The test environment uses :null_store, which drops everything written to it, so the
  # task and the endpoint could never agree here without a store that remembers.
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }

  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |t| t.name == 'deploy:mark_deployment_id' }
  end

  before do
    Rake::Task[task_name].reenable
    allow(Rails).to receive(:cache).and_return(cache)
    allow(Git).to receive(:revision).and_return('abc123def')
  end

  it 'registers the running revision' do
    Rake::Task[task_name].invoke

    expect(cache.read('registered-deployment-id')).to eq('abc123def')
  end

  it 'registers a value the status endpoint reports as matching the running revision' do
    Rake::Task[task_name].invoke

    get '/system_status/details'

    payload = JSON.parse(response.body)
    expect(payload['registered_deployment_id']).to eq('abc123def')
    expect(payload['registered_deployment_id']).to eq(payload['revision'])
  end

  it 'reports a mismatch while deploy tasks have not run for the serving code' do
    get '/system_status/details'

    payload = JSON.parse(response.body)
    expect(payload['registered_deployment_id']).to be_nil
    expect(payload['revision']).to eq('abc123def')
  end
end
