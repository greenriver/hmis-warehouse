###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# The nightly job wrapper around Idp::Keycloak::AuthenticationSourceBackfill. The
# linking logic and the advisory lock are covered elsewhere; this pins only the
# dispatch the wrapper adds: iterate every active Idp::ServiceConfig and run the
# backfill for each service that supports it, keyed on that config's connector_id.
RSpec.describe Idp::Keycloak::BackfillAuthenticationSourcesJob, type: :job do
  let(:job) { described_class.new }
  let(:result) { Idp::Keycloak::AuthenticationSourceBackfill::Result.new(total: 0, linked: 0, already: 0, missing: 0) }

  before do
    # Run the instrumented body inline, holding the (stubbed) advisory lock, so the
    # spec exercises the real config iteration without touching the task-run tables.
    allow(GrdaWarehouseBase).to receive(:with_advisory_lock) { |*_args, &block| block.call }
    allow(job).to receive(:instrument_as_maintenance_task).and_yield(double('run', complete!: true))
    allow(Idp::Keycloak::AuthenticationSourceBackfill).to receive(:call).and_return(result)
  end

  it 'backfills each active config keyed on its connector_id, skipping inactive ones' do
    create(:idp_service_config, connector_id: 'kc-a', active: true)
    create(:idp_service_config, connector_id: 'kc-b', active: true)
    create(:idp_service_config, connector_id: 'kc-inactive', active: false)

    job.perform

    expect(Idp::Keycloak::AuthenticationSourceBackfill).to have_received(:call).
      with(service: kind_of(Idp::KeycloakService), connector_id: 'kc-a')
    expect(Idp::Keycloak::AuthenticationSourceBackfill).to have_received(:call).
      with(service: kind_of(Idp::KeycloakService), connector_id: 'kc-b')
    expect(Idp::Keycloak::AuthenticationSourceBackfill).not_to have_received(:call).
      with(hash_including(connector_id: 'kc-inactive'))
  end

  it 'skips services that do not support account backfill' do
    create(:idp_service_config, connector_id: 'kc-a', active: true)
    # A provider that only authenticates exposes no backfill capability.
    allow_any_instance_of(Idp::ServiceConfig).to receive(:to_service).and_return(Idp::NullService.new('kc-a'))

    job.perform

    expect(Idp::Keycloak::AuthenticationSourceBackfill).not_to have_received(:call)
  end
end
