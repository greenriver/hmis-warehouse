###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Mutations::AcHmis::BulkVoidCeClients, type: :request do
  include_context 'hmis base setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation BulkVoidCeClients($destinationClientIds: [ID!]!, $projectId: ID!) {
        bulkVoidCeClients(destinationClientIds: $destinationClientIds, projectId: $projectId) {
          success
        }
      }
    GRAPHQL
  end

  let!(:ce_project) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1, project_type: 14) }
  let!(:access_control) { create_access_control(hmis_user, ce_project, with_permission: [:can_administrate_coordinated_entry, :can_view_enrollment_details, :can_view_project, :can_view_clients, :can_edit_enrollments]) }
  let!(:client_1) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1) }
  let!(:client_2) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1) }
  let(:destination_client_ids) { [client_1.warehouse_id.to_s, client_2.warehouse_id.to_s] }

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:bulk_void_enabled?).and_return(true)
    hmis_login(user)
    clear_enqueued_jobs
  end

  def perform_mutation(destination_client_ids: self.destination_client_ids, project_id: ce_project.id)
    post_graphql(destination_client_ids: destination_client_ids, project_id: project_id) { mutation }
  end

  it 'denies access when the feature flag is disabled' do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:bulk_void_enabled?).and_return(false)

    expect_access_denied perform_mutation
    expect(enqueued_jobs).to be_empty
  end

  it 'denies access without can_administrate_coordinated_entry' do
    remove_permissions(access_control, :can_administrate_coordinated_entry)

    expect_access_denied perform_mutation
    expect(enqueued_jobs).to be_empty
  end

  it 'denies access when can_administrate_coordinated_entry is only granted in another data source' do
    remove_permissions(access_control, :can_administrate_coordinated_entry)
    other_data_source = create(:hmis_data_source)
    create_access_control(hmis_user, other_data_source, with_permission: [:can_administrate_coordinated_entry])

    expect_access_denied perform_mutation
    expect(enqueued_jobs).to be_empty
  end

  it 'denies access without can_edit_enrollments in the selected CE project' do
    remove_permissions(access_control, :can_edit_enrollments)

    expect_access_denied perform_mutation
    expect(enqueued_jobs).to be_empty
  end

  it 'denies access when the selected project is not a CE project' do
    non_ce_project = create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1, project_type: 1)
    create_access_control(hmis_user, non_ce_project, with_permission: [:can_view_enrollment_details, :can_view_project, :can_view_clients, :can_edit_enrollments])

    expect_access_denied perform_mutation(project_id: non_ce_project.id)
    expect(enqueued_jobs).to be_empty
  end

  it 'denies access when any destination client is not found' do
    destination_client_ids << '0'

    expect_access_denied perform_mutation
    expect(enqueued_jobs).to be_empty
  end

  it 'denies access when any destination client is not viewable' do
    inaccessible_project = create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1)
    create(:hmis_hud_enrollment, data_source: ds1, project: inaccessible_project, client: client_2)

    expect_access_denied perform_mutation
    expect(enqueued_jobs).to be_empty
  end

  it 'enqueues the job and returns success when allowed' do
    expect do
      response, result = perform_mutation

      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'bulkVoidCeClients', 'success')).to eq(true)
    end.to change(enqueued_jobs, :count).by(1)

    enqueued_job = enqueued_jobs.find { |job| job[:job] == HmisExternalApis::AcHmis::BulkVoidCeClientsJob }
    expect(enqueued_job).to be_present
    expect(enqueued_job[:queue]).to eq(ENV.fetch('DJ_LONG_QUEUE_NAME', 'long_running'))
    expect(enqueued_job[:priority]).to eq(BaseJob::UI_IMMEDIATE_PRIORITY_NEG5)
    expect(enqueued_job[:args].first).to include(
      'destination_client_ids' => destination_client_ids,
      'ce_project_id' => ce_project.id,
      'initiated_by_id' => hmis_user.id,
    )
  end
end
