###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'

RSpec.describe 'Client dashboard disability rollups', type: :request do
  include_context 'visibility test context'

  before do
    GrdaWarehouse::Config.delete_all
    GrdaWarehouse::Config.invalidate_cache
    Collection.maintain_system_groups
  end

  after do
    GrdaWarehouse::Config.invalidate_cache
  end

  let!(:config) { create :config_b }
  let!(:user) { create :acl_user }
  let!(:can_view_hiv_status) { create :role, can_view_hiv_status: true }

  let!(:hiv_disability) do
    create(
      :hud_disability,
      data_source_id: window_visible_data_source.id,
      PersonalID: window_source_client.PersonalID,
      EnrollmentID: window_enrollment.EnrollmentID,
      DisabilityType: 8,
      DisabilityResponse: 1,
      InformationDate: window_enrollment.EntryDate,
    )
  end

  def request_disabilities
    get rollup_client_path(window_destination_client, partial: :disabilities), xhr: true
  end

  def request_disability_types
    get rollup_client_path(window_destination_client, partial: :disability_types), xhr: true
  end

  before do
    setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
    setup_access_control(user, can_search_own_clients, Collection.system_collection(:window_data_sources))
    setup_access_control(user, can_view_hiv_status, Collection.system_collection(:window_data_sources))
    sign_in user
  end

  context 'with permission to view HIV status' do
    it "shows the HIV disability response on an unrestricted client's disabilities rollup" do
      request_disabilities

      expect(response.body).to include('Yes')
      expect(response.body).not_to include('redacted')
    end

    it "shows the HIV disability response on an unrestricted client's disability types rollup" do
      request_disability_types

      expect(response.body).to include('Yes')
      expect(response.body).not_to include('[redacted]')
    end

    it 'redacts the HIV disability response once the client is restricted, on the disabilities rollup' do
      Hmis::RestrictedRecord.create!(
        restrictable_id: window_source_client.id,
        restrictable_type: 'Hmis::Hud::Client',
        data_source_id: window_source_client.data_source_id,
        created_by: Hmis::User.find(user.id),
      )

      request_disabilities

      expect(response.body).to include('redacted')
    end

    it 'redacts the HIV disability response once the client is restricted, on the disability types rollup' do
      Hmis::RestrictedRecord.create!(
        restrictable_id: window_source_client.id,
        restrictable_type: 'Hmis::Hud::Client',
        data_source_id: window_source_client.data_source_id,
        created_by: Hmis::User.find(user.id),
      )

      request_disability_types

      expect(response.body).to include('[redacted]')
    end
  end

  context 'without permission to view HIV status' do
    let!(:can_view_hiv_status) { create :role }

    it 'redacts the HIV disability response on the disabilities rollup regardless of restriction' do
      request_disabilities

      expect(response.body).to include('HIV/AIDS')
      expect(response.body).to include('redacted')
    end

    it 'redacts the HIV disability response on the disability types rollup regardless of restriction' do
      request_disability_types

      expect(response.body).to include('HIV/AIDS')
      expect(response.body).to include('[redacted]')
    end
  end
end
