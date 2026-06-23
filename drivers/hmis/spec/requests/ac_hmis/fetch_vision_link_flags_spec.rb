###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let(:stub_aha) { double }
  let!(:aha_credential) do
    GrdaWarehouse::RemoteCredentials::ApiKey.first_or_create!(
      slug: 'ac_hmis_aha',
      active: true,
      endpoint: 'https://example.com',
      password: 'test-token',
      username: '',
    )
  end
  let!(:mci_unique_id) { create(:mci_unique_id_external_id, source: c1) }
  let!(:e1) { create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c1) }
  let!(:access_control) do
    create_access_control(
      hmis_user,
      p1,
      with_permission: [:can_view_clients, :can_view_project, :can_view_enrollment_details, :can_edit_enrollments],
    )
  end

  before(:each) do
    hmis_login(user)
    allow(HmisExternalApis::AcHmis::Aha).to receive(:new).and_return(stub_aha)
    allow(HmisExternalApis::AcHmis::Aha).to receive(:enabled?).and_return(true)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation FetchVisionLinkFlags($clientId: ID!) {
        fetchVisionLinkFlags(clientId: $clientId) {
          isEligibleRa
          section8
          cityOfPittsburgh
          subsidizedHousing
          recentEvictionCase
          dwClientId
          failedReason
          #{error_fields}
        }
      }
    GRAPHQL
  end

  def perform_mutation(client_id:)
    response, result = post_graphql(client_id: client_id) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      data = result.dig('data', 'fetchVisionLinkFlags')
      errors = result.dig('data', 'fetchVisionLinkFlags', 'errors')
      yield data, errors
    end
  end

  it 'returns VisionLink flags when present' do
    visionlink_result = HmisExternalApis::AcHmis::AhaScores::VisionLinkResult.new(
      score: 0.12,
      dw_client_id: mci_unique_id.value,
      generator: 'Visionlink 2.0',
      is_eligible_ra: true,
      section_8: false,
      city_of_pittsburgh: false,
      subsidized_housing: false,
      recent_eviction_case: false,
    )
    allow(stub_aha).to receive(:fetch_score).with(
      c1,
      requested_generators: [:visionlink],
    ).and_return({ visionlink: visionlink_result })

    perform_mutation(client_id: c1.id) do |data, errors|
      expect(errors).to be_empty
      expect(data['isEligibleRa']).to eq(true)
      expect(data['section8']).to eq(false)
      expect(data['subsidizedHousing']).to eq(false)
      expect(data['recentEvictionCase']).to eq(false)
      expect(data['failedReason']).to be_nil
    end
  end

  it 'returns null flags when VisionLink entry is missing' do
    allow(stub_aha).to receive(:fetch_score).with(
      c1,
      requested_generators: [:visionlink],
    ).and_return({ visionlink: nil })

    perform_mutation(client_id: c1.id) do |data, errors|
      expect(errors).to be_empty
      expect(data['isEligibleRa']).to be_nil
      expect(data['section8']).to be_nil
      expect(data['failedReason']).to be_nil
    end
  end

  it 'returns failedReason when client has no MCI unique ID' do
    client_without_mci = create(:hmis_hud_client, data_source: ds1, user: u1)
    create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: client_without_mci)
    allow(stub_aha).to receive(:fetch_score).with(
      client_without_mci,
      requested_generators: [:visionlink],
    ).and_raise(HmisExternalApis::AcHmis::Aha::NoMciUniqueIdError)

    perform_mutation(client_id: client_without_mci.id) do |data, errors|
      expect(errors).to be_empty
      expect(data['failedReason']).to eq('NO_MCI_UNIQUE_ID')
      expect(data['isEligibleRa']).to be_nil
    end
  end

  context 'when user cannot edit enrollments' do
    let!(:access_control) do
      create_access_control(
        hmis_user,
        p1,
        with_permission: [:can_view_clients, :can_view_project, :can_view_enrollment_details],
      )
    end

    it 'returns access denied error' do
      expect_access_denied(post_graphql(client_id: c1.id) { mutation })
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
