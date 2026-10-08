###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/visibility_test_context'

RSpec.describe GrdaWarehouse::Hud::Client, type: :model do
  include_context 'visibility test context'

  let!(:config) { create :config_b }
  let!(:user) { create :acl_user }

  before do
    Collection.maintain_system_groups
  end

  describe '.source_visible_to with client_ids, access through assigned projects' do
    before do
      setup_access_control(user, can_view_clients, Collection.system_collection(:window_data_sources))
    end

    it 'returns only the requested clients the user can see' do
      ids = [window_source_client.id, non_window_source_client.id]

      expect(described_class.source_visible_to(user, client_ids: ids).pluck(:id)).to contain_exactly(window_source_client.id)
    end

    it 'excludes visible clients that were not requested' do
      expect(described_class.source_visible_to(user).pluck(:id)).to include(window_source_client_2.id)

      result = described_class.source_visible_to(user, client_ids: [window_source_client.id])

      expect(result.pluck(:id)).to contain_exactly(window_source_client.id)
    end

    it 'ignores destination ids mixed into client_ids' do
      ids = [window_source_client.id, window_destination_client.id]

      expect(described_class.source_visible_to(user, client_ids: ids).pluck(:id)).to contain_exactly(window_source_client.id)
    end

    it 'treats an empty client_ids list as no restriction' do
      expect(described_class.source_visible_to(user, client_ids: []).pluck(:id)).
        to match_array(described_class.source_visible_to(user).pluck(:id))
    end

    it 'exposes only the destinations of visible requested source clients' do
      ids = [window_source_client.id, non_window_source_client.id]

      expect(described_class.destination_visible_to(user, source_client_ids: ids).pluck(:id)).
        to contain_exactly(window_destination_client.id)
    end

    # Guards query cost, not results: without this restriction Postgres builds every
    # client the user can see before checking the requested ids.
    it 'restricts each visibility subquery to the requested client ids' do
      ids = [window_source_client.id, non_window_source_client.id]
      restriction = "#{described_class.quoted_table_name}.\"id\" IN (#{ids.join(', ')})"

      sql = described_class.source_visible_to(user, client_ids: ids).to_sql

      expect(sql.scan(restriction).size).to eq(3)
    end
  end

  describe '.source_visible_to with client_ids, access through a release of information' do
    before do
      setup_access_control(user, can_view_client_enrollments_with_roi, Collection.system_collection(:window_data_sources))
      window_destination_client.update!(
        housing_release_status: described_class.full_release_string,
        consent_form_signed_on: 5.days.ago,
        consent_expires_on: Date.current + 1.year,
      )
    end

    it 'returns only the requested clients covered by a release' do
      ids = [window_source_client.id, window_source_client_2.id, non_window_source_client.id]

      expect(described_class.source_visible_to(user, client_ids: ids).pluck(:id)).to contain_exactly(window_source_client.id)
    end
  end
end
